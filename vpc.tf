resource "aws_vpc" "self_managed_vpc" {   //prod-vpc
    cidr_block = "10.1.0.0/24"
    enable_dns_support = "true" #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name    
    tags = {
    Name = "self_managed_vpc"
  }

}

// public subnet
resource "aws_subnet" "self-managed-public-subnet" {
    vpc_id = "${aws_vpc.self_managed_vpc.id}"
    cidr_block = "10.1.0.0/25"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1a"
   tags = {
    Name = "self-managed-public-subnet"
  }

}

# create an IGW (Internet Gateway)
# It enables your vpc to connect to the internet
resource "aws_internet_gateway" "self-managed-igw" {
    vpc_id = "${aws_vpc.self_managed_vpc.id}"
   tags = {
    Name = "self-managed-igw"
  }

}








# create a custom route table for public subnets
# public subnets can reach to the internet buy using this
resource "aws_route_table" "self-managed-public-rt" {
    vpc_id = "${aws_vpc.self_managed_vpc.id}"
    route {
        cidr_block = "0.0.0.0/0" //associated subnet can reach everywhere
        gateway_id = "${aws_internet_gateway.self-managed-igw.id}" //CRT uses this IGW to reach internet
    }
   tags = {
    Name = "self-managed-public-rt"
  }

}

# route table association for the public subnets
resource "aws_route_table_association" "self-managed-public-rt-asc" {
    subnet_id = "${aws_subnet.self-managed-public-subnet.id}"
    route_table_id = "${aws_route_table.self-managed-public-rt.id}"

  

}








/*
# security group
resource "aws_security_group" "ssh-allowed" {

    vpc_id = "${aws_vpc.self_managed_vpc.id}"

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        
        // This means, all ip address are allowed to ssh !
        // Do not do it in the production. Put your office or home address in it!
        cidr_blocks = ["0.0.0.0/0"]
    }

}
*/
// private subnet

resource "aws_subnet" "self-managed-private-subnet" {
  vpc_id     = aws_vpc.self_managed_vpc.id
  cidr_block = "10.1.0.128/25"
  availability_zone = "us-east-1b"

  tags = {
    Name = "self-managed-private-subnet"
  }
}


# elastic ip

resource "aws_eip" "self-managed-ngw-eip" {
  vpc = true
   tags = {
    Name = "self-managed-ngw-eip"
  } 
}


# create nat gateway in public subnet

resource "aws_nat_gateway" "self-managed-ngw" {
  allocation_id = aws_eip.self-managed-ngw-eip.id
  subnet_id     = aws_subnet.self-managed-public-subnet.id
     tags = {
    Name = "self-managed-ngw"
  } 
}

# create private route table
resource "aws_route_table" "self-managed-private-rt" {
    vpc_id = aws_vpc.self_managed_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.self-managed-ngw.id
    }

    tags = {
        Name = "self-managed-private-rt"
    }
}

# private route table subnet associates

resource "aws_route_table_association" "self-managed-private-rt-asc" {
    subnet_id = aws_subnet.self-managed-private-subnet.id
    route_table_id = aws_route_table.self-managed-private-rt.id
    
        
  

}

resource "aws_security_group" "ec2-jump-sg" {
  name = "ec2-jump-sg"
  
  vpc_id = aws_vpc.self_managed_vpc.id

  // To Allow SSH Transport
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

 

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}