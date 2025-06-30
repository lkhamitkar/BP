locals {
  userdata_file = var.userdata_file != "" ? abspath(var.userdata_file) : ""
  node_group_tags = merge({
    Name = join("-", [var.cluster_name, var.node_group_name_prefix])
    },
  var.node_group_tags)
}
