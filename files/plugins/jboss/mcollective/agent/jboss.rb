module MCollective
  module Agent
    class Jboss<RPC::Agent
 
		action "cli" do
			reply[:status] = run("./jboss-cli.sh -c --controller='#{Facts["ipaddress"]}' --user=#{request[:cli_user]} --password=#{request[:cli_pwd]} command='#{request[:command]}'", :stdout => :out, :stderr => :err, :cwd => "/opt/jboss/bin")
			reply[:out].chomp!
			reply[:err].chomp!
			reply[:msg] = cli_command

		end
# /profile=ha/subsystem=datasources/data-source=reportsDS:add(jndi-name="java:/Reports",  driver-name="mysql",
  # driver-class="com.mysql.jdbc.Driver", connection-url="jdbc:mysql://195.84.86.39:3306/reports", user-name="root",
  # password="Open-Dai2012"
		action "deploy" do
		end

		action "create_datasource" do
			if request[:domain_mode] == "standalone"
				cli_command = "./jboss-cli.sh -c --controller='#{Facts["ipaddress"]}' --user=#{request[:cli_user]} --password=#{request[:cli_pwd]} command='deploy /tmp/#{request[:artefact]} #{force}'"
			else
				cli_command = "./jboss-cli.sh -c --controller='#{Facts["ipaddress"]}' --user=#{request[:cli_user]} --password=#{request[:cli_pwd]} command='/profile=#{request[:profile]}/subsystem=datasources/data-source=#{request[:datasource]}:add(jndi-name=\"#{request[:jndi_name]}\",  driver-name=\"#{request[:driver]}\",driver-class=\"#{request[:driver_class]}\", connection-url=\"#{request[:connection_url]}\", user-name=\"#{request[:db_user]}\",password=\"#{request[:db_pwd]}\"'"
			end
			reply[:status] = run(cli_command, :stdout => :out, :stderr => :err, :cwd => "/opt/jboss/bin")
			reply[:out].chomp!
			reply[:err].chomp!
			reply[:msg] = cli_command
		end

		action "deploy_url" do
				get_out = ""
				get_err = ""
                # wget the artefact to /tmp
				get_status = run("wget --quiet --output-document=/tmp/#{request[:artefact]} '#{request[:url]}#{request[:artefact]}'", :stdout => get_out, :stderr => get_err, :cwd => "/tmp")
				Log.warn("wget --quiet --output-document=/tmp/#{request[:artefact]} '#{request[:url]}#{request[:artefact]}'")
				Log.warn(get_out)
				Log.warn(get_err)
				
				#deploy in JBossAS
				if File.exists?("/tmp/#{request[:artefact]}")
					if request[:server_groups] == "all"
						server_group = "--all-server-groups"
					else
						server_group = "--server-groups=#{request[:server_groups]}"
					end
					
					if request[:force_deploy]
						force = "--force"
					else
						force = ""
					end
					
				
					if request[:domain_mode] == "standalone"
						cli_command = "./jboss-cli.sh -c --controller='#{Facts["ipaddress"]}' --user=#{request[:cli_user]} --password=#{request[:cli_pwd]} command='deploy /tmp/#{request[:artefact]} #{force}'"
					else
						cli_command = "./jboss-cli.sh -c --controller='#{Facts["ipaddress"]}' --user=#{request[:cli_user]} --password=#{request[:cli_pwd]} command='deploy /tmp/#{request[:artefact]} #{server_group} #{force}'"
					end
					reply[:status] = run(cli_command, :stdout => :out, :stderr => :err, :cwd => "/opt/jboss/bin")
					reply[:out].chomp!
					reply[:err].chomp!
					reply[:msg] = cli_command
				else
					reply[:msg] = get_err
				end
				reply[:out].chomp!
				reply[:err].chomp!
            
		end

		action "server_status" do
		end

		action "app_status" do
		end

    end
  end
end
