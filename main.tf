resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}
resource "aws_subnet" "sub1" {
    vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.1.0.0/24"
  availability_zone = "us-west-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-west-1b"
  map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "igw" {
  vpc_id     = aws_vpc.myvpc.id
}
resource "aws_route_table" "RT" {
  vpc_id     = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

     }
 }
 resource "aws_route_table_association" "rta1" {
   subnet_id      = aws_subnet.sub1.id
   route_table_id = aws_route_table.RT.id
}
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}
resource "aws_security_group" "sg" {
  name        = "websg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "websecuritygp"
  }
}
resource "aws_key_pair" "deployer" {
  key_name   = "terraform"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuf1uaY2MvgQ5FOu4AkPOytz9voImyuqL/OFJfWU+8eJbkwvJFx7ZFy10jW2fSQVMxN+EcsAGphLOHiU2ufFFL6OBoZmY7I/7BZ5XFL2zGYf+MBShFXguba1Z/SraqAoV+FnvM6gA2f45jb9iDcKMVlpgeM7ckddSdZ81jZ70vsFzkXntp1S0NOKUymJAoe7QDozh/R+KWZrxjD0MpOd/oDsX4ZTMGeOvZA1dUoV7JZPXo0Vqm2boWw8BxADLxHHYFdwfP03HFkPOBhJi0zZHzI9El05upd+WnlbFRwIrmogpuXKxZaEPu64KRf6APoP6l4DEr9PJwVhGEosk2xYBFaz7hqi8th7xdUxU2EMjFtWp5ulcrQOlj72RoKPZrkTapAna4fUWRkJ9PUZuLY8KZU2qooSjp1a+K4ZnDdcYb26Py/e5HCnK8lPFB9Sfu4UGlc78+phziBrwVMii4BmD5Ve6t3EVZEBVNH8P1oVG1b1GomYZkwwynx/KjnFW2KUE= My-PC@DESKTOP-P88EJN0"
}
resource "aws_instance" "Server" {
    ami = "ami-0cbd40f694b804622"
    instance_type = "t2.micro"
    key_name = "terraform"
    vpc_security_group_ids = [aws_security_group.sg.id]
    subnet_id = aws_subnet.sub1.id
    user_data              = base64encode(file("userdata.sh"))
    provisioner "file" {
    source      = "C:\\Users\\My-PC\\Desktop\\terraformproject\\terraform-ansible-configuration\\playbook.yml" # Path to the local file
    destination = "/home/ubuntu/playbook.yml" # Path to the file on the remote server
      connection {
        type        = "ssh"
        user        = "ubuntu" # Change this to the appropriate user for your AMI
        private_key = file("~/terraform.pem")
        host        = aws_instance.Server.public_ip
      }
    }
  provisioner "local-exec" {
  command = "ansible-playbook -i /etc/ansible/hosts /playbook.yml"
   }

  # provisioner "remote-exec" {
  # inline = [
  #   "echo 'Running Ansible playbook'",
  #   "ansible-playbook -i /etc/ansible /home/ubuntu/playbook.yml -b"
  # ]
      # connection {
      #   type        = "ssh"
      #   user        = "ubuntu"
      #   private_key = file("~/terraform.pem")
      #   host        = aws_instance.Server.public_ip
      # }
    # }
}

resource "aws_instance" "Server2" {
  ami                    = "ami-0cbd40f694b804622"
  instance_type          = "t2.micro"
  key_name = "terraform"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.sub2.id
}




