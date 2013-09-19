=begin
service 'ssh' do
  action :nothing
end
=end

group "deploy" do
  # No pb4us user yet, but we'll add it later once it exists:
  members ["root", node['current_user']]
end

ruby_block 'remember-auth-sock' do
  block do
    ssh_auth_sock = ENV['SSH_AUTH_SOCK']
    node.default['ssh_agent_forwarding']['auth_sock'] = ssh_auth_sock
  end
end

template node['ssh_agent_forwarding']['ssh_wrapper'] do
  source 'wrap-ssh4git.sh.erb'
  owner 'root'
  group 'deploy'
  mode '777'
end

bash 'update-rights-for-forwarding' do
  code <<-EOF
    set -e
    chgrp deploy $SSH_AUTH_SOCK
    chgrp deploy `dirname $SSH_AUTH_SOCK`
    chmod 770 $SSH_AUTH_SOCK
    chmod 770 `dirname $SSH_AUTH_SOCK`
  EOF
  only_if { File.exists?(node['ssh_agent_forwarding']['auth_sock']) }
end

