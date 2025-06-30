package test

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"strconv"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/gruntwork-io/terratest/modules/testing"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func CheckMetadataAccess(t testing.TestingT, workerNodes1Opts *terraform.Options, enabled string, hopLimit int, tokensRequired string) {
	test_structure.RunTestStage(t, "test_workernode_output", func() {
		httpEndpoint := terraform.Output(t, workerNodes1Opts, "launch_template_metadata_option_http_endpoint")
		httpPutResponseHopLimit, err := strconv.Atoi(terraform.Output(t, workerNodes1Opts, "launch_template_metadata_option_http_put_response_hop_limit"))
		require.NoError(t, err, "Unable convert http_put_response_hop_limit output to int")
		httpTokens := terraform.Output(t, workerNodes1Opts, "launch_template_metadata_option_http_tokens")

		assert.Equal(t, enabled, httpEndpoint, fmt.Sprintf("Terraform output for %s does not match desired value of %s", "httpEndpoint", enabled))
		assert.Equal(t, hopLimit, httpPutResponseHopLimit, fmt.Sprintf("Terraform output for %s does not match desired value of %d", "httpPutResponseHopLimit", hopLimit))
		assert.Equal(t, tokensRequired, httpTokens, fmt.Sprintf("Terraform output for %s does not match desired value of %s", "httpTokens", tokensRequired))
	})
}

// CheckNatStackConfig used to confirm NAT configuration
func CheckNatStackConfig(t testing.TestingT, ec2NatOpts *terraform.Options, resourceName string, env string) {
	// Set map of relevant subnet ids
	test_structure.RunTestStage(t, "test_nat_stack_config", func() {
		subnetIds := map[string]string{
			"prod_private_az1":    "subnet-05154d8f27b4716a7",
			"prod_private_az2":    "subnet-05e066724acf03f0c",
			"prod_private_az3":    "subnet-0bce7680f3e13857a",
			"staging_private_az1": "subnet-05154d8f27b4716a7",
			"staging_private_az2": "subnet-05e066724acf03f0c",
			"staging_private_az3": "subnet-0bce7680f3e13857a",
			"dev_private_az1":     "subnet-01e02664935a35ff9",
			"dev_private_az2":     "subnet-093b57c7b4711c892",
			"dev_private_az3":     "subnet-09ffd575c82056788",
		}

		// Ensure outputs for AZ1 Instance is correct
		name := terraform.Output(t, ec2NatOpts, "nat_az1_name")
		assert.Equal(t, fmt.Sprintf("ec2-%s-1", resourceName), name)

		role := terraform.Output(t, ec2NatOpts, "nat_az1_role")
		assert.Equal(t, fmt.Sprintf("%s-1Role", resourceName), role)

		privateEni := terraform.OutputMap(t, ec2NatOpts, "nat_az1_private_eni")
		assert.Equal(t, subnetIds[fmt.Sprintf("%s_private_az1", env)], privateEni["subnet_id"])
		assert.Equal(t, "false", privateEni["source_dest_check"])

		// Ensure outputs for AZ2 Instance is correct
		name = terraform.Output(t, ec2NatOpts, "nat_az2_name")
		assert.Equal(t, fmt.Sprintf("ec2-%s-2", resourceName), name)

		role = terraform.Output(t, ec2NatOpts, "nat_az2_role")
		assert.Equal(t, fmt.Sprintf("%s-2Role", resourceName), role)

		privateEni = terraform.OutputMap(t, ec2NatOpts, "nat_az2_private_eni")
		assert.Equal(t, subnetIds[fmt.Sprintf("%s_private_az2", env)], privateEni["subnet_id"])
		assert.Equal(t, "false", privateEni["source_dest_check"])

		// Ensure outputs for AZ3 Instance is correct
		name = terraform.Output(t, ec2NatOpts, "nat_az3_name")
		assert.Equal(t, fmt.Sprintf("ec2-%s-3", resourceName), name)

		role = terraform.Output(t, ec2NatOpts, "nat_az3_role")
		assert.Equal(t, fmt.Sprintf("%s-3Role", resourceName), role)

		privateEni = terraform.OutputMap(t, ec2NatOpts, "nat_az3_private_eni")
		assert.Equal(t, subnetIds[fmt.Sprintf("%s_private_az3", env)], privateEni["subnet_id"])
		assert.Equal(t, "false", privateEni["source_dest_check"])
	})
}

// CheckNatIPMaps checks that the configured mapping of NAT az to IP used for routing traffic to cn-dtag is correct
func CheckNatIPMaps(t testing.TestingT, workerNodesTFOptions *terraform.Options, ec2NatTFOptions *terraform.Options, env string) {
	azShortNameMap := map[string]string{
		"eu-central-1a": "az1",
		"eu-central-1b": "az2",
		"eu-central-1c": "az3",
	}

	test_structure.RunTestStage(t, "test_nat_ip_map", func() {
		natIPMap := terraform.OutputMap(t, workerNodesTFOptions, "nat_az_to_ip_map")
		fmt.Printf("Map of AZ to IP is: %s \n", natIPMap)
		for az, ip := range natIPMap {
			natAzIP := string(terraform.OutputMap(t, ec2NatTFOptions, fmt.Sprintf("nat_%s_private_eni", azShortNameMap[az]))["private_ips"])
			natAzIP = natAzIP[1 : len(natAzIP)-1]
			fmt.Println("NatAZIP is : ", natAzIP)
			if assert.Equal(t, ip, natAzIP) {
				fmt.Println("[PASS]", az, "is correctly mapped to", ip)
			} else {
				fmt.Println("[FAILED]", az, "is incorrectly mapped to", ip, "it should be", natAzIP)
			}
		}
	})
}

// CheckSubnets Checks the subnet output values of a terraform deployment
func CheckSubnets(t testing.TestingT, terraformOptions *terraform.Options, env string, subnetAmount int) {
	subnetIds := map[string]string{
		"prod_private_az1":    "subnet-05154d8f27b4716a7",
		"prod_private_az2":    "subnet-05e066724acf03f0c",
		"prod_private_az3":    "subnet-0bce7680f3e13857a",
		"staging_private_az1": "subnet-05154d8f27b4716a7",
		"staging_private_az2": "subnet-05e066724acf03f0c",
		"staging_private_az3": "subnet-0bce7680f3e13857a",
		"dev_private_az1":     "subnet-01e02664935a35ff9",
		"dev_private_az2":     "subnet-093b57c7b4711c892",
		"dev_private_az3":     "subnet-09ffd575c82056788",
		"prod_cn_dtag_az1":    "subnet-02c50cc15eaf3a29f",
		"prod_cn_dtag_az2":    "subnet-0cd666b4f32075d5d",
		"prod_cn_dtag_az3":    "subnet-0eba388838f1b94bf",
		"staging_cn_dtag_az1": "subnet-02c50cc15eaf3a29f",
		"staging_cn_dtag_az2": "subnet-0cd666b4f32075d5d",
		"staging_cn_dtag_az3": "subnet-0eba388838f1b94bf",
		"dev_cn_dtag_az1":     "subnet-065761c0ec9f760a7",
		"dev_cn_dtag_az1_new": "subnet-07f7fc2361a24d37e",
		"dev_cn_dtag_az2":     "subnet-07ab7fda96660795f",
		"dev_cn_dtag_az3":     "subnet-07d444dc79d00631c",
	}

	test_structure.RunTestStage(t, "test_subnets", func() {
		clusterSubnets := terraform.OutputList(t, terraformOptions, "workers_asg_subnets")
		fmt.Printf("Internal subnets are: %s \n", clusterSubnets)
		assert.Equal(t, len(clusterSubnets), subnetAmount, fmt.Sprintf("Subnet list is too long. Has %d but should have %d", len(clusterSubnets), subnetAmount))
		assert.Equal(t, true, stringInSlice(subnetIds[fmt.Sprintf("%s_private_az1", env)], clusterSubnets), "Subnets don't match!")
		if subnetAmount > 1 {
			assert.Equal(t, true, stringInSlice(subnetIds[fmt.Sprintf("%s_private_az2", env)], clusterSubnets), "Subnets don't match!")
		}
		if subnetAmount > 2 {
			assert.Equal(t, true, stringInSlice(subnetIds[fmt.Sprintf("%s_private_az3", env)], clusterSubnets), "Subnets don't match!")
		}
	})
}

// ChangeSubnetDefinitions used to test manual definition of subnets
func ChangeSubnetDefinitions(t testing.TestingT, terraformOptions *terraform.Options, copyFromTfvar string, tfvarsFile string, clusterPath string) {
	test_structure.RunTestStage(t, "test_subnet_definition", func() {
		err := files.CopyFile(copyFromTfvar, filepath.Join(clusterPath, tfvarsFile))
		assert.NoError(t, err, "Unable to copy tfvars file")

		fmt.Println("Replacing values in tfvars")
		out, err := exec.Command("../scripts/prepare_subnet_test.sh", clusterPath).CombinedOutput()
		fmt.Printf("output is %s\n", out)
		if err != nil {
			fmt.Println(err)
			assert.FailNow(t, "Unable to prepare subnet test")
		}

		exitCode := terraform.PlanExitCode(t, terraformOptions)
		if !assert.Equal(t, exitCode, 0, "Terraform plan returned an unexpected diff!") {
			terraform.Plan(t, terraformOptions)
		} else {
			fmt.Println("Subnet definition test passed succesfully.")
		}
	})
}

func stringInSlice(a string, list []string) bool {
	for _, b := range list {
		fmt.Printf("Comparing to : %s\n", b)
		if b == a {
			fmt.Printf("%s - Found!\n", a)
			return true
		}
	}
	return false
}
