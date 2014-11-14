package "curl-devel"

gem_package "passenger" do
  version node["passenger"]["version"]
  not_if "gem list | egrep 'passenger \\(#{node[:passenger][:version]}'"
end

include_recipe "opsworks-passenger::custom_package"

directory node[:nginx][:dir] do
  owner "root"
  group "root"
  mode "0755"
end

%w{shared_server.conf.d http_server.conf.d ssl_server.conf.d}.each do |dir|
  directory File.join(node[:nginx][:dir], dir) do
    owner "root"
    group "root"
    mode "0755"
  end
end

directory node[:nginx][:log_dir] do
  mode 0755
  owner node[:nginx][:user]
end

%w{sites-available sites-enabled conf.d}.each do |dir|
  directory File.join(node[:nginx][:dir], dir) do
    owner "root"
    group "root"
    mode "0755"
  end
end

%w{nxensite nxdissite}.each do |nxscript|
  template "/usr/sbin/#{nxscript}" do
    cookbook "nginx"
    source "#{nxscript}.erb"
    mode 0755
    owner "root"
    group "root"
  end
end

bash "Setup Nginx integration in passenger gem" do
  code "rake nginx RELEASE=yes"
  cwd node[:passenger][:root]
  not_if { File.directory? "#{node[:passenger][:root]}/agents" }
end

include_recipe "nginx::service"
service "nginx" do
  action [ :enable, :start ]
end

