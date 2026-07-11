output "shared_vpc_id" {
  value = aws_vpc.shared.id
}

output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.this.id
}
