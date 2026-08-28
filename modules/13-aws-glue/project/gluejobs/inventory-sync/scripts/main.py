import sys

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

REQUIRED_ARGS = ["JOB_NAME", "env", "api_endpoint", "batch_size"]

sc = SparkContext()
glue_context = GlueContext(sc)
job = Job(glue_context)

args = getResolvedOptions(sys.argv, REQUIRED_ARGS)
job.init(args["JOB_NAME"], args)

print(f"Syncing inventory for {args['env']} via {args['api_endpoint']}")
print(f"Batch size: {args['batch_size']}")

job.commit()
