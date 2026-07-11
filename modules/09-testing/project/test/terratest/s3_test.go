package terratest

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestS3BucketModule(t *testing.T) {
	t.Parallel()

	awsRegion := "us-east-1"
	bucketName := fmt.Sprintf("terratest-s3-%s", strings.ToLower(random.UniqueId()))

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/s3_bucket",
		Vars: map[string]interface{}{
			"bucket_name":        bucketName,
			"force_destroy":      true,
			"versioning_enabled": true,
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "Terratest",
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	assert.Equal(t, bucketName, terraform.Output(t, terraformOptions, "bucket_name"))
	assert.Equal(t, "Enabled", terraform.Output(t, terraformOptions, "versioning_status"))
	assert.Equal(t, "AES256", terraform.Output(t, terraformOptions, "encryption_algorithm"))

	aws.AssertS3BucketExists(t, awsRegion, bucketName)
}

