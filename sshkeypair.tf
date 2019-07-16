resource "aws_key_pair" "default" {
  key_name = "zookeeperServerKeyPair"
  public_key = "${file("${var.key_path}")}"
}
