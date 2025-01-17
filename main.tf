resource "aws_vpc" "gary_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "gary_public_subnet" {
  vpc_id                  = aws_vpc.gary_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "gary_igw" {
  vpc_id = aws_vpc.gary_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "gary_public_rt" {
  vpc_id = aws_vpc.gary_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "gary_route" {
  route_table_id         = aws_route_table.gary_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gary_igw.id
  depends_on             = [aws_internet_gateway.gary_igw]
}

resource "aws_route_table_association" "gary_public_subnet_association" {
  subnet_id      = aws_subnet.gary_public_subnet.id
  route_table_id = aws_route_table.gary_public_rt.id
}

resource "aws_security_group" "gary_sg" {
  vpc_id = aws_vpc.gary_vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_key_pair" "gary_key" {
  key_name   = "gary_key"
  public_key = file("~/.ssh/awsGaryKey.pub")
}

resource "aws_instance" "gary_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.gary_key.key_name
  subnet_id     = aws_subnet.gary_public_subnet.id
  vpc_security_group_ids = [aws_security_group.gary_sg.id]
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-instance"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname = self.public_ip,
      user     = "ubuntu",
      identityfile = "~/.ssh/awsGaryKey"
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }
}


