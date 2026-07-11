moved {
  from = aws_vpc.main
  to   = module.networking.aws_vpc.this
}

moved {
  from = aws_internet_gateway.main
  to   = module.networking.aws_internet_gateway.this
}

moved {
  from = aws_subnet.public
  to   = module.networking.aws_subnet.public
}

moved {
  from = aws_route_table.public
  to   = module.networking.aws_route_table.public
}

moved {
  from = aws_route_table_association.public
  to   = module.networking.aws_route_table_association.public
}

moved {
  from = aws_security_group.web
  to   = module.web_security_group.aws_security_group.this
}

moved {
  from = aws_instance.web
  to   = module.web.aws_instance.this
}
