resource "aws_network_interface" "main" {
  count           = "${var.cnt}"
  subnet_id       = "${element(var.subnet_ids, count.index)}"
  private_ips     = ["${cidrhost(element(var.subnet_cidr, count.index), 5)}"]
  security_groups = ["${aws_security_group.zookeeper-server.id}"]
}

resource "aws_instance" "zookeeper" {
  count                   = "${var.cnt}"
  ami                     = "${var.ami}"
  instance_type           = "${var.instance_type}"
  ebs_optimized           = "${var.ebs_optimized}"
  disable_api_termination = "${var.disable_api_termination}"
  monitoring              = "${var.monitoring}"
  key_name 		  = "${aws_key_pair.default.id}"

  network_interface {
    network_interface_id = "${element(aws_network_interface.main.*.id, count.index)}"
    device_index         = 0
  }

  tags = {
    Name = "${var.name}-zookeeper-${count.index}"
  }
}

resource "aws_volume_attachment" "zk-instance" {
  count       = "${var.cnt}"
  device_name = "/dev/sdb"
  volume_id   = "${aws_ebs_volume.this[count.index].id}"
  instance_id = "${element(aws_instance.zookeeper.*.id, count.index)}"
  skip_destroy = true
}

resource "aws_ebs_volume" "this" {
  count             = "${var.cnt}"
  availability_zone = "${element(var.subnet_az, count.index)}"
  size              = 4
  type              = "io1"
  iops		    = 100
}

resource "aws_security_group" "zookeeper-server" {
  name   = "zookeeper-server"
  vpc_id = "vpc-0d2fe90286b6e30ea"

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
}
