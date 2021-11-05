provider "aws" {
    version   = "~> 2.0"
     access_key = "AKIA4BK6ZDYO35OVEXZY"
     secret_key = "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"
     region  = "eu-west-2"

}

terraform {
    required_version = ">= 0.12.0"

    backend "s3" {
        bucket  = "bucketfrec2"
        key     = "ec2/ec2deploy.tfstate"
        region  = "eu-west-2"
        access_key = "AKIA4BK6ZDYO4SEFBO7G"
        secret_key = "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"

    }
}

data "aws_ami" "filter" {
  most_recent = true
  owners = ["self"]
  tags = {
       Name = "ami-app"
 }
}
  
resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
       Name = "Testing"
  }
}

resource "aws_subnet" "test_subnet" {
  vpc_id = aws_vpc.test_vpc.id
  availability_zone = "eu-west-2b"
  cidr_block = "10.0.1.0/24"
  tags = {
       Name = "Testing"
  }
}

resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id
  tags = {
       Name = "Testing"
  }
}

resource "aws_route_table" "test-rt" {
 vpc_id = aws_vpc.test_vpc.id
 route {
 cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.test_igw.id
 }
 tags = {
       Name = "Testing"
  }
}

resource "aws_route_table_association" "test-rt_ass" {
  subnet_id = aws_subnet.test_subnet.id
  route_table_id = aws_route_table.test-rt.id
}

resource "aws_security_group" "ssh-allowed" {
    vpc_id = aws_vpc.test_vpc.id

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "test_instance" {
    ami   = data.aws_ami.filter.id
    availability_zone = "eu-west-2b"
    instance_type = var.instance_type
    subnet_id = aws_subnet.test_subnet.id
    vpc_security_group_ids= [aws_security_group.ssh-allowed.id]
}

resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.test_instance.id
  allocation_id = aws_eip.eip.id
}


resource "aws_ebs_volume" "test_ebs" {
    availability_zone = "eu-west-2b"
    size              = "20"
    tags = {
      Name = "Test_volume"
    }
}

resource "aws_volume_attachment" "ebs_att" {
   device_name = "/dev/sdh"
   volume_id = aws_ebs_volume.test_ebs.id
   instance_id = aws_instance.test_instance.id
}


