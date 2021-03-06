metadata :name => "jboss",
         :description => "JBoss AS plugin",
         :author => "Luca Gioppo",
         :license => "GPLv2",
         :version => "1.0",
         :url => "https://github.com/gioppoluca/mcollective-jboss",
         :timeout => 60

action "cli", :description => "Execute a CLI command" do
     display :always
 
    input :cli_user,
          :prompt      => "CLI User",
          :description => "The CLI user",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30

	input :cli_pwd,
          :prompt      => "CLI user password",
          :description => "The CLI user password",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30

	input :command,
          :prompt      => "CLI user password",
          :description => "The CLI user password",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_()=:,\/\d]+$',
          :optional    => false,
          :maxlength   => 30

	output :msg,
           :description => "The message we received",
           :display_as  => "Message"
		   
	output :status,
           :description => "The status of service",
           :display_as  => "Service Status",
           :default     => "unknown status"
	output :out,
           :description => "The answer of the call",
           :display_as  => "Output",
           :default     => "unknown answer"
	output :err,
           :description => "The error",
           :display_as  => "Service error",
           :default     => "unknown error"
end

action "deploy", :description => "Deploy artefact from File System" do
	display :always
 
    input :cli_user,
          :prompt      => "CLI User",
          :description => "The CLI user",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30
end

action "create_datasource", :description => "Create a datasource" do
	display :always
 
    input :cli_user,
          :prompt      => "CLI User",
          :description => "The CLI user",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30

	input :cli_pwd,
          :prompt      => "CLI user password",
          :description => "The CLI user password",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30

	input :domain_mode,
          :prompt      => "JBoss domain mode",
          :description => "The domain mode the server is on",
          :type        => :list,
          :optional    => false,
		  :list        => ["standalone", "domain"],
          :maxlength   => 30

	input :profile,
          :prompt      => "The server profile",
          :description => "The CLI user password",
          :type        => :string,
		  :default     => "HA",
          :validation  => '^[a-zA-Z\-_()=:,\/\d]+$',
          :optional    => true,
          :maxlength   => 30

	input :datasource,
          :prompt      => "Datasource name",
          :description => "The name of the datasource",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30

	input :jndi_name,
          :prompt      => "jndi_name",
          :description => "The name of the jndi value",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_:\/\d]+$',
          :optional    => false,
          :maxlength   => 30

	input :driver,
          :prompt      => "Driver name",
          :description => "The name of the driver",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30

	input :driver_class,
          :prompt      => "Driver class",
          :description => "The class of the driver",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_.\d]+$',
          :optional    => false,
          :maxlength   => 30

	input :connection_url,
          :prompt      => "Connection URL",
          :description => "The URl to connect to the DB",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_:.\/\d]+$',
          :optional    => false,
          :maxlength   => 30

    input :db_user,
          :prompt      => "CLI User",
          :description => "The CLI user",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30

	input :db_pwd,
          :prompt      => "CLI user password",
          :description => "The CLI user password",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30

	output :msg,
           :description => "The message we received",
           :display_as  => "Message"
		   
	output :status,
           :description => "The status of service",
           :display_as  => "Service Status",
           :default     => "unknown status"
	output :out,
           :description => "The answer of the call",
           :display_as  => "Output",
           :default     => "unknown answer"
	output :err,
           :description => "The error",
           :display_as  => "Service error",
           :default     => "unknown error"
end

action "deploy_url", :description => "Deploy artefact from URL" do
	display :always
 
    input :cli_user,
          :prompt      => "CLI User",
          :description => "The CLI user",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30

	input :cli_pwd,
          :prompt      => "CLI user password",
          :description => "The CLI user password",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30

	input :url,
          :prompt      => "URL",
          :description => "The path",
          :type        => :string,
          :validation  => '^http\://[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$',
          :optional    => false,
          :maxlength   => 100

	input :artefact,
          :prompt      => "Stuff to deploy",
          :description => "The artefact",
          :type        => :string,
          :validation  => '^[0-9A-Za-z_]+(.[wWeE][aA][rR]|.[vV][dD][bB])$',
          :optional    => false,
          :maxlength   => 30

	input :domain_mode,
          :prompt      => "JBoss domain mode",
          :description => "The domain mode the server is on",
          :type        => :list,
          :optional    => false,
		  :list        => ["standalone", "domain"],
          :maxlength   => 30

	input :server_groups,
          :prompt      => "Server groups where to deploy",
          :description => "The artefact",
          :type        => :string,
		  :default     => "all",
		  :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 100

	input :force_deploy,
          :prompt      => "Force deploy if exist",
          :description => "Force deploy",
          :type        => :boolean,
		  :default     => false,
          :optional    => true,
          :maxlength   => 100

	output :msg,
           :description => "The message we received",
           :display_as  => "Message"
		   
	output :status,
           :description => "The status of service",
           :display_as  => "Service Status",
           :default     => "unknown status"
	output :out,
           :description => "The answer of the call",
           :display_as  => "Output",
           :default     => "unknown answer"
	output :err,
           :description => "The error",
           :display_as  => "Service error",
           :default     => "unknown error"
end

action "server_status", :description => "Return the server status" do
	display :always
 
    input :cli_user,
          :prompt      => "CLI User",
          :description => "The CLI user",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30
end

action "app_status", :description => "Return the application status" do
	display :always
 
    input :cli_user,
          :prompt      => "CLI User",
          :description => "The CLI user",
          :type        => :string,
          :validation  => '^[a-zA-Z\-_\d]+$',
          :optional    => false,
          :maxlength   => 30
end
