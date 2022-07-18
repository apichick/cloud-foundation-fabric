# Azure AD configuration for Anthos Identity Service

This is an example that uses Terraform to configure Azure AD for Anthos identity service following the guidelines provided [here](https://cloud.google.com/anthos/identity/setup/provider#azure-ad).

## Running the example

Clone this repository or [open it in cloud shell](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fterraform-google-modules%2Fcloud-foundation-fabric&cloudshell_print=cloud-shell-readme.txt&cloudshell_working_dir=examples%2Fcloud-operations%2Fanthos_azuread), then go through the following steps to create resources:

* `terraform init`
* `terraform apply -var tenant_id=my-tenant-id`

## Testing the example

Once the resources have been created, do the following to verify that everything works as expected.

1. Obtain the configuration for Anthos running following command:

        terraform output -raw config
    
2. Run the following command in your cluster:

        kubectl --kubeconfig=KUBECONFIG_PATH edit ClientConfigs default -n kube-public

3. Update the contents of ```spec.authentication``` with the configuration obtained in step 1.

Once done testing, you can clean up resources by running `terraform destroy`.
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [tenant_id](variables.tf#L17) | tenant_id | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [config](outputs.tf#L17) | Configuration to use in Anthos | ✓ |

<!-- END TFDOC -->
