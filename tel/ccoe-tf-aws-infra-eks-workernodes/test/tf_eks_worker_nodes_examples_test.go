package test

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	tf_common "gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-int-test/modules/common"
	"gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-int-test/modules/eks"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	// testutils "k8s.io/kubernetes/test/utils"
)

// This example breaks the test up into stages so you can skip any stage foo by setting the environment variable
// SKIP_foo=true.

func TestTerraformExamples(t *testing.T) {
	t.Parallel()
	var err error

	// Since we want to be able to run multiple tests in parallel on the same modules, we need to copy them into
	// temp folders so that the state files and .terraform folders don't clash
	env := os.Getenv("environment")
	logic := os.Getenv("logic_test")
	nodegroupFolder := os.Getenv("EXAMPLE_FOLDER")

	if env == "" {
		env = "dev"
	}

	clusterPath := "eks_cluster/"
	workerNodes1Path := test_structure.CopyTerraformFolderToTemp(t, "..", nodegroupFolder)
	ec2natTFDir := tf_common.CopyFolderToTemp(t, "..", "test/ec2_nat")
	clusterTFDir := test_structure.CopyTerraformFolderToTemp(t, "..", "test/eks_cluster")

	clustertfvarsFile := fmt.Sprintf("%s.tfvars", env)
	nattfvarsFile := fmt.Sprintf("%s.tfvars", env)
	workernodestfvarsFile := fmt.Sprintf("%s.tfvars", env)

	subnetAmount := 3
	nodeAmount := 1

	if logic == "true" {
		subnetAmount = 1
		workernodestfvarsFile = fmt.Sprintf("logic_%s.tfvars", env)
	}

	workspaceName := os.Getenv("WORKSPACENAME")
	workerNodeBackend := os.Getenv("WORKERNODES_BACKEND_CONFIG_PATH")
	natBackend := os.Getenv("EC2_NAT_BACKEND_CONFIG_PATH")
	clusterBackend := os.Getenv("EKS_CLUSTER_BACKEND_CONFIG_PATH")

	var checkIdempotent bool
	if os.Getenv("CHECK_IDEMPOTENT") == "" || strings.ToLower(os.Getenv("CHECK_IDEMPOTENT")) == "false" {
		checkIdempotent = false
	} else {
		checkIdempotent = true
	}

	// Copy cluster TF Vars
	err = files.CopyFile(filepath.Join(clusterPath, clustertfvarsFile), filepath.Join(clusterTFDir, clustertfvarsFile))
	if err != nil {
		t.Fatal(err)
	}

	if clusterBackend != "" || natBackend != "" || workerNodeBackend != "" {
		err = files.CopyFile("provider.tf", filepath.Join(workerNodes1Path, "provider.tf"))
		if err != nil {
			t.Fatal(err)
		}
	}

	awsRegion := "eu-central-1"

	// A unique ID we can use to namespace all our resource names and ensure they don't clash across parallel tests
	uniqueID := random.UniqueId()

	var_cluster_name := fmt.Sprintf("infra-wn-%s", uniqueID)
	var clusterBackendConfig map[string]interface{}
	if clusterBackend != "" {
		terraform.GetAllVariablesFromVarFile(t, clusterBackend, &clusterBackendConfig)
		var_cluster_name = workspaceName
	}

	// Deploy the Eks Cluster module
	eksClusterOpts := &terraform.Options{}

	// Undeploy the Eks Cluster module at the end of the test
	defer test_structure.RunTestStage(t, "cleanup_eks_cluster", func() {
		eksClusterOpts = test_structure.LoadTerraformOptions(t, clusterTFDir)
		terraform.Init(t, eksClusterOpts)
		if clusterBackend != "" {
			terraform.WorkspaceSelectOrNew(t, eksClusterOpts, workspaceName)
		}
		tagSubnets := terraform.OutputList(t, eksClusterOpts, "subnet_tag_cluster_shared")
		clusterId := terraform.Output(t, eksClusterOpts, "cluster_id")
		terraform.Destroy(t, eksClusterOpts)
		tagShared := map[string]string{
			fmt.Sprintf("kubernetes.io/cluster/%s", clusterId): "shared",
		}
		for _, subnet := range tagSubnets {
			fmt.Printf("Removing shared tag from subnet: %s\n", subnet)
			tf_common.RemoveTagsFromResourceE(t, awsRegion, subnet, tagShared)
		}
		test_structure.CleanupTestDataFolder(t, clusterTFDir)
		test_structure.CleanupTestDataFolder(t, ".")
		if clusterBackend != "" {
			terraform.WorkspaceDelete(t, eksClusterOpts, workspaceName)
		}
	})

	test_structure.RunTestStage(t, "eks_cluster", func() {
		eksClusterOpts = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where our Terraform code is located
			TerraformDir: clusterTFDir,

			// Variables to pass to our Terraform code using -var options
			VarFiles: []string{clustertfvarsFile},

			Vars: map[string]interface{}{
				"cluster_name": var_cluster_name,
			},

			BackendConfig: clusterBackendConfig,

			// Environment variables to set when running Terraform
			EnvVars: map[string]string{
				"AWS_DEFAULT_REGION": awsRegion,
			},
		})
		eksClusterOpts = tf_common.TerraformInitAndApply(t, clusterTFDir, eksClusterOpts, workspaceName, checkIdempotent)

		test_structure.SaveString(t, ".", "clusterId", terraform.Output(t, eksClusterOpts, "cluster_id"))
		test_structure.SaveString(t, ".", "cluster_security_group_id", terraform.Output(t, eksClusterOpts, "cluster_security_group_id"))
		test_structure.SaveString(t, ".", "worker_iam_role_arn", terraform.Output(t, eksClusterOpts, "worker_iam_role_arn"))
	})

	clusterId := tf_common.GetOutput(t, ".", eksClusterOpts, "clusterId")

	natInstanceName := fmt.Sprintf("%s-nat", clusterId)
	// var natBackendConfig map[string]interface{}
	// if natBackend != "" {
	// 	terraform.GetAllVariablesFromVarFile(t, natBackend, &natBackendConfig)
	// 	var_cluster_name = workspaceName
	// }

	// Deploy EC2 NAT module
	ec2NatOpts := &terraform.Options{}

	// Undeploy the Eks Cluster module at the end of the test
	defer test_structure.RunTestStage(t, "cleanup_ec2_nat", func() {
		ec2NatOpts := test_structure.LoadTerraformOptions(t, ec2natTFDir)
		if natBackend != "" {
			terraform.WorkspaceSelectOrNew(t, ec2NatOpts, workspaceName)
		}
		// We do not init here, because the nat module need to have protect from delete disabled
		terraform.Destroy(t, ec2NatOpts)
		test_structure.CleanupTestDataFolder(t, ec2natTFDir)
		if clusterBackend != "" {
			terraform.WorkspaceDelete(t, ec2NatOpts, workspaceName)
		}
	})

	test_structure.RunTestStage(t, "ec2_nat", func() {
		ec2NatOpts = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where our Terraform code is located
			TerraformDir: ec2natTFDir,

			// Variables to pass to our Terraform code using -var options
			VarFiles: []string{nattfvarsFile},

			Vars: map[string]interface{}{
				"instance_name":     natInstanceName,
				"purpose_tag_value": fmt.Sprintf("NAT for test %s", clusterId),
			},
			// BackendConfig: natBackendConfig,

			// Environment variables to set when running Terraform
			EnvVars: map[string]string{
				"AWS_DEFAULT_REGION": awsRegion,
			},
		})
		if test_structure.IsTestDataPresent(t, test_structure.FormatTestDataPath(ec2natTFDir, "TerraformOptions.json")) {
			ec2NatOpts = test_structure.LoadTerraformOptions(t, ec2natTFDir)
		} else {
			test_structure.SaveTerraformOptions(t, ec2natTFDir, ec2NatOpts)
		}
		if natBackend != "" {
			terraform.WorkspaceSelectOrNew(t, ec2NatOpts, workspaceName)
		}
		// We do not init here, because the nat module need to have protect from delete disabled
		terraform.Apply(t, ec2NatOpts)
	})

	var workerBackendConfig map[string]interface{}
	nodegroupNamePrefix := fmt.Sprintf("infra-wn-%s", uniqueID)
	if workerNodeBackend != "" {
		nodegroupNamePrefix = os.Getenv("NODEGROUP_PREFIX")
		terraform.GetAllVariablesFromVarFile(t, workerNodeBackend, &workerBackendConfig)
		workerBackendConfig["key"] = fmt.Sprintf("workernodes-%s/terraform.tfstate", nodegroupNamePrefix)
	}

	// Deploy the Worker Nodes module
	workerNodes1Opts := &terraform.Options{}

	// Undeploy the Worker Node module at the end of the test
	defer test_structure.RunTestStage(t, "cleanup_worker_nodes1", func() {
		// Copy Worker node TF Vars
		err = files.CopyFile(filepath.Join("..", nodegroupFolder, workernodestfvarsFile), filepath.Join(workerNodes1Path, workernodestfvarsFile))
		if err != nil {
			t.Fatal(err)
		}

		tf_common.TerraformInitAndDestroy(t, workerNodes1Path, workspaceName)
	})

	test_structure.RunTestStage(t, "worker_nodes1", func() {
		// Copy Worker node TF Vars
		err = files.CopyFile(filepath.Join("..", nodegroupFolder, workernodestfvarsFile), filepath.Join(workerNodes1Path, workernodestfvarsFile))
		if err != nil {
			t.Fatal(err)
		}

		workerNodes1Opts = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where our Terraform code is located
			TerraformDir: workerNodes1Path,

			// Variables to pass to our Terraform code using -var options
			VarFiles: []string{workernodestfvarsFile},

			Vars: map[string]interface{}{
				"cluster_name":           clusterId,
				"node_group_name_prefix": nodegroupNamePrefix,
				"nat_purpose_tag_value":  fmt.Sprintf("NAT for test %s", clusterId),
			},

			BackendConfig: workerBackendConfig,

			// Environment variables to set when running Terraform
			EnvVars: map[string]string{
				"AWS_DEFAULT_REGION": awsRegion,
			},
		})

		workerNodes1Opts = tf_common.TerraformInitAndApply(t, workerNodes1Path, workerNodes1Opts, workspaceName, checkIdempotent)
	})

	var clientset kubernetes.Interface
	var kubeconfigPath string

	test_structure.RunTestStage(t, "test_preparation", func() {
		workerNodes1Opts = test_structure.LoadTerraformOptions(t, workerNodes1Path)
		ec2NatOpts = test_structure.LoadTerraformOptions(t, ec2natTFDir)
		eksClusterOpts = test_structure.LoadTerraformOptions(t, clusterTFDir)

		kubeconfigPath = filepath.Join(clusterTFDir, filepath.Base(terraform.Output(t, eksClusterOpts, "kubeconfig_filename")))
		config, err := clientcmd.BuildConfigFromFlags("", kubeconfigPath)
		assert.NoError(t, err)

		clientset, err = kubernetes.NewForConfig(config)
		assert.NoError(t, err)

		nodeAmount, err = strconv.Atoi(terraform.Output(t, workerNodes1Opts, "desired_size"))
		require.NoError(t, err, "Unable convert desired size output to int")
	})

	enabled := "enabled"
	hopLimit := 1
	tokensRequired := "required"

	if logic == "true" {
		hopLimit = 0
		tokensRequired = "optional"
	}

	CheckMetadataAccess(t, workerNodes1Opts, enabled, hopLimit, tokensRequired)

	CheckNatStackConfig(t, ec2NatOpts, natInstanceName, env)
	CheckNatIPMaps(t, workerNodes1Opts, ec2NatOpts, env)

	CheckSubnets(t, workerNodes1Opts, env, subnetAmount)

	if logic != "true" && checkIdempotent {
		ChangeSubnetDefinitions(t, workerNodes1Opts, workernodestfvarsFile, workernodestfvarsFile, workerNodes1Path)
	}

	// We no longer need to run eks.CheckWorkerNodes as managed node group deployment
	// already handles that. The deployment will fail if the nodes do not join the cluster.
	eks.CheckKubernetesCluster(t, clientset, nodeAmount, true, false, false, true, clusterId, kubeconfigPath)
}
