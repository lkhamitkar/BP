module ccoe-tf-aws-infra-eks-workernodes

go 1.14

require (
	github.com/aws/aws-sdk-go v1.27.1
	github.com/golangplus/bytes v0.0.0-20160111154220-45c989fe5450 // indirect
	github.com/golangplus/fmt v0.0.0-20150411045040-2a5d6d7d2995 // indirect
	github.com/gruntwork-io/terratest v0.32.24
	github.com/sirupsen/logrus v1.6.0 // indirect
	github.com/stretchr/testify v1.7.0
	github.com/xlab/handysort v0.0.0-20150421192137-fb3537ed64a1 // indirect
	gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-int-test v0.0.23
	k8s.io/api v0.21.0
	k8s.io/apimachinery v0.21.0
	k8s.io/client-go v0.21.0
	k8s.io/kubectl v0.21.0
	sigs.k8s.io/kustomize v2.0.3+incompatible // indirect
	vbom.ml/util v0.0.0-20160121211510-db5cfe13f5cc // indirect
)

replace gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-int-test => gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-int-test.git v0.0.23
