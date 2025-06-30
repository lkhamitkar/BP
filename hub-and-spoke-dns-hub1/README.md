# dns-hub
# Introduction
Currently connected spokes are not generally available to customers as they do not meet the requirements for outbound DNS filtering.

This repo/pipeline manages the deployment of connected Network and Route53 Resolver resources as part of the managed DNS solution for the AWS platform.

Using the more flexible approach of using a single (DNS Hub) account with multiple VPCs in order to accommodate new regions.

### DNS Hub spoke accounts:

| Branch | Spoke Name | Account ID | Hub env. |
| - | - | - | - |
| develop | WS-Z068 | 213804799719 | H1 |
| staging | WS-Y08C | 808294362653 | H2 |
| master  | WS-00GT | 048910124132 | H3 |

Design to be implemented: https://basproducts.atlassian.net/wiki/spaces/CSL/pages/1721794950/AWS+Hub+and+Spoke+-+Hybrid+DNS+Design

For Ireland, Ohio, N.Virginia, Singapore and Sydney regions the `network-connected-vpc` CFN stack is automatically deployed via Gitlab CI pipeline using aws cli in the following accounts:

* WS-Z068
* WS-Y08C
* WS-00GT

This stack is responsible of creating:

* ConnectedTgw VPC - has got network connection to on-prem via Transit Gateway Attachment
* Subnets /27 per AZ for Inbound and Outbound Endpoints
* Route Tables with default route via Transit Gateway ID

The deployment is split into 3 steps:
1. First part deploys all the resources except for the Routes for CD2 domain DNS servers in Prime P1.
2. Next you need to manualy setup a peering to the WE1-P1 or WU2-P1 account VPCs (depending on the region)
3. Lastly you need deploy the routes leading to the P1 accounts through the peering id from the previous step and set it here: `P1_VPC_PEERING_ID` and deploy the routes in the P1 account VPCs leading back to the DNS Hub. The routes should be added here [VPC CloudFormation stacks IaaS accounts](https://git.0404.p1.we1.r53.cd2.bp.com/enterprise/networking/vpc)

VPC CIDR block range allocation for Ireland:
| Hub env.| Spoke Name | Spoke Account ID | VPC CIDR |
| - | - | - | - |
| H1 | WS-Z068 | 213804799719 | 10.57.254.0/24 |
| H2 | WS-Y08C | 808294362653 | 10.57.234.0/24 |
| H3 | WS-00GT | 048910124132 | 10.56.70.0/24  |

VPC CIDR block range allocation for Ohio:
| Hub env.| Spoke Name | Spoke Account ID | VPC CIDR |
| - | - | - | - |
| H1 | WS-Z068 | 213804799719 | 10.49.250.0/24 |
| H2 | WS-Y08C | 808294362653 | 10.49.234.0/24 |
| H3 | WS-00GT | 048910124132 | 10.48.30.0/24  |

VPC CIDR block range allocation for N.Virginia:
| Hub env.| Spoke Name | Spoke Account ID | VPC CIDR |
| - | - | - | - |
| H1 | WS-Z068 | 213804799719 | 10.189.124.0/24 |
| H2 | WS-Y08C | 808294362653 | 10.189.116.0/24 |
| H3 | WS-00GT | 048910124132 | 10.189.1.0/24   |

VPC CIDR block range allocation for Singapore:
| Hub env.| Spoke Name | Spoke Account ID | VPC CIDR |
| - | - | - | - |
| H1 | WS-Z068 | 213804799719 | 10.188.249.0/24 |
| H2 | WS-Y08C | 808294362653 | 10.188.233.0/24 |
| H3 | WS-00GT | 048910124132 | 10.188.1.0/24   |

VPC CIDR block range allocation for Sydney:
| Hub env.| Spoke Name | Spoke Account ID | VPC CIDR |
| - | - | - | - |
| H1 | WS-Z068 | 213804799719 | 10.170.124.0/24 |
| H2 | WS-Y08C | 808294362653 | 10.170.116.0/24 |
| H3 | WS-00GT | 048910124132 | 10.170.0.0/24   |

VPC CIDR block range allocation for Jakarta:
| Hub env.| Spoke Name | Spoke Account ID | VPC CIDR |
| - | - | - | - |
| H1 | WS-Z068 | 213804799719 | 10.191.126.0/24 |
| H2 | WS-Y08C | 808294362653 | 10.191.122.0/24 |
| H3 | WS-00GT | 048910124132 | 10.191.64.0/24   |

For more details please refer:
[AWS Network & CIDR ranges](https://basproducts.atlassian.net/wiki/spaces/CSL/pages/75825248/AWS+Network+CIDR+ranges)
[DNS Resources](https://basproducts.atlassian.net/wiki/spaces/CSL/pages/3117449884/AWS+Hub+and+Spoke+-+DNS+Resources)

In order the DNS Hub spokes in the H1/H2/H3 to skip receiving network service stack updates the parameters in Dynamo DB been updated removing following fields:

* "connectivity-type"
* "network-type"
* "internet-facing"
* "network-private"

`IMPORTANT`: do NOT remove these fields as they are part of other services deployment:

* "network_access": "full"   =>  deploys TGW assotiation with full access TGW route table
* "ip-range": "10.x.x.x/24,10.x.x.x/24"  => e.g. as comma-separated value

## Example of manual Network stack deployment to "WS-Z068" DNS Hub for new region in H1 for Singapore region:

```bash
VPC_CIDR: 10.188.249.0/24
TGW_ID: tgw-0fe8f79e54dfcc4fb
AWS_DEFAULT_REGION: ap-southeast-1

- |
  aws cloudformation deploy \
    --template-file cfn/network-connected-vpc.yaml \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-NETWORK-STACK \
    --parameter-overrides Cidr=${VPC_CIDR} \
      TransitGatewayId=${TGW_ID} \
    --capabilities CAPABILITY_NAMED_IAM \
    --role-arn arn:aws:iam::${ACCOUNT_NO}:role/${APP_NAME}-DeploymentRole \
    --no-fail-on-empty-changeset
```

Once deployment is completed, update the `"ip-range"` parameter in Dynamo DB adding a new VPC CIDR range as comma-separated value from AWS console in H1.

`IMPORTANT`: do NOT remove `"ArePeeringRoutesRequired"` condition from `"network-connected-vpc"` template, it is required if the template needs to be deployed to a new region before the peerings are creating.

## DNS Route53 Resolver - Deployed in CIP and DNS Hub accounts

[The architectural design for the DNS H&S Service can be found in Confluence](https://basproducts.atlassian.net/wiki/spaces/CSL/pages/1721794950/AWS+Hub+and+Spoke+-+Hybrid+DNS+Design)

 The `dns-resolver.yaml` template, and it's dependencies been moved here from the `dns-service` repository thus allowing centrally manage Route53 Resolver resources. Please refer to the [PBI-1576808](https://bp-vsts.visualstudio.com/AWS_CIP/_workitems/edit/1576808) for more details.

The `dns-resolver` CFN stack is automatically deployed via Gitlab CI automation using aws cli in the following accounts:

* WS-Z068
* WS-Y08C
* WS-00GT

This stack is responsible of creating:

* A Security Groups that will be used by Route53 Resolver Outbound & Inbound Endpoints
* Multiple Route53 Resolver Rules that are all part of the RAM Resource Share
* A RAM Resource Share that is dynamically share Route53 Resolver Rules with following principles:
    * Connected, IaaS and Shared Services OUs in Ireland, Ohio, N.Virginia and Singapore regions

* The Route53 Resolver Outbound Endpoint using hardcoded IP addresses (Firewall exception have been made for this IP to allow traffic on port 53 between CIP and H&S) used by some of the Route53 Resolver Rules
* An IAM Role that will be used by `dns-service` Lambda to share the RAM Share Resource with each spoke that is created

## Example of manual Route53 Resolver deployment to "WS-Z068" DNS Hub in H1 for Singapore region:

```bash
ENVIRONMENT: WS-Z068
ACCOUNT_NO: 213804799719
BP1_DNS_1: 149.184.178.128
BP1_DNS_2: 149.184.178.129
BP1_DNS_3: 149.189.146.40
BP1_DNS_4: 149.189.147.40
IN_RESOLVER_AZa_IP: 10.188.249.4
OUT_RESOLVER_AZa_IP: 10.188.249.5
IN_RESOLVER_AZb_IP: 10.188.249.36
OUT_RESOLVER_AZb_IP: 10.188.249.37
AWS_DEFAULT_REGION: ap-southeast-1

- VPC_ID=(`aws cloudformation describe-stacks --stack-name ${ENVIRONMENT}-${APP_NAME}-NETWORK-STACK --query "Stacks[0].Outputs[?OutputKey=='VPC'].OutputValue" --output text`)
- RESOLVER_AZa_SUBNET=(`aws cloudformation describe-stacks --stack-name ${ENVIRONMENT}-${APP_NAME}-NETWORK-STACK --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnetA'].OutputValue" --output text`)
- RESOLVER_AZb_SUBNET=(`aws cloudformation describe-stacks --stack-name ${ENVIRONMENT}-${APP_NAME}-NETWORK-STACK --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnetB'].OutputValue" --output text`)
- >
  aws cloudformation deploy \
    --template-file cfn/dns-resolver.yaml \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-CFN-DNS-RESOLVER \
    --capabilities CAPABILITY_NAMED_IAM \
    --role-arn arn:aws:iam::${ACCOUNT_NO}:role/${APP_NAME}-DeploymentRole \
    --parameter-overrides BP1DnsServer1=${BP1_DNS_1} \
      BP1DnsServer2=${BP1_DNS_2} \
      BP1DnsServer3=${BP1_DNS_3} \
      BP1DnsServer4=${BP1_DNS_4} \
      InboundResolverEndpointAZaIP=${IN_RESOLVER_AZa_IP} \
      OutboundResolverEndpointAZaIP=${OUT_RESOLVER_AZa_IP} \
      ResolverEndpointAZaSubnet=${RESOLVER_AZa_SUBNET} \
      InboundResolverEndpointAZbIP=${IN_RESOLVER_AZb_IP} \
      OutboundResolverEndpointAZbIP=${OUT_RESOLVER_AZb_IP} \
      ResolverEndpointAZbSubnet=${RESOLVER_AZb_SUBNET} \
      VpcId=${VPC_ID} \
      OrganizationsID=${ORGANIZATIONS_ID} \
      ProdOrgUnitID=${PROD_OU_ID} \
      NonProdOrgUnitID=${NON_PROD_OU_ID} \
      SharedServicesOrgUnitID=${SHAREDSERVICES_OU_ID} \
      IaaSProdOUID=${IAAS_PROD_OU_ID} \
      IaaSNonProdOUID=${IAAS_NONPROD_OU_ID} \
    --tags cloud-environment=${ENVIRONMENT}-${CE_NAME} \
    --no-fail-on-empty-changeset
- unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN
```
