require "googleauth"
require "grpc"
require "google/datastore/v1/datastore_services_pb"

class GRPC_repro
  def initialize

  end

  def init_vars
    # Get the environment configured authorization
    scopes = ["https://www.googleapis.com/auth/datastore"]
    authorization = Google::Auth.get_application_default scopes

    host = "datastore.googleapis.com"
    call_credentials = GRPC::Core::CallCredentials.new authorization.updater_proc
    channel_credentials = GRPC::Core::ChannelCredentials.new.compose call_credentials
    @project = ENV["GRPC_REPRO_PROJECT"] || "nodal-almanac-725"
    @stub = Google::Datastore::V1::Datastore::Stub.new host, channel_credentials
  end

  def init_vars_2
    # Get the environment configured authorization
    new_scopes = ["https://www.googleapis.com/auth/datastore"]
    new_authorization = Google::Auth.get_application_default new_scopes

    new_host = "datastore.googleapis.com"
    new_call_credentials = GRPC::Core::CallCredentials.new new_authorization.updater_proc
    new_channel_credentials = GRPC::Core::ChannelCredentials.new.compose new_call_credentials
    @project_new = ENV["GRPC_REPRO_PROJECT"] || "nodal-almanac-725"
    @stub_new = Google::Datastore::V1::Datastore::Stub.new new_host, new_channel_credentials
  end

  def print_output(project, stub)
    puts "Starting the process to call GRPC..."

    lookup_key = Google::Datastore::V1::Key.new(
      path: [Google::Datastore::V1::Key::PathElement.new(kind: "Person", name: "blowmage")])
    puts "The key we are going to lookup is #{lookup_key}"

    lookup_req = Google::Datastore::V1::LookupRequest.new(
      project_id: project,
      keys: [lookup_key]
    )
    puts "The lookup request we are going to make is #{lookup_req}"

    puts "The stub we are going to use is #{stub}"

    puts "calling..."
    lookup_res = stub.lookup lookup_req
    puts "call completed"

    puts "The lookup result is #{lookup_res}"
  end

  def start
    puts "*"*72
    puts "Make GRPC call in forked process 1"
    puts "*"*72
    puts ""
    fork {
      init_vars
      print_output(@project, @stub)
    }
    Process.wait

    puts "*"*72
    puts "Make GRPC call in forked process"
    puts "*"*72
    make_fork_call
    puts ""
  end

  def make_fork_call
    fork {
      init_vars_2 
      print_output(@project_new, @stub_new) 
    }
    Process.wait
  end
end

repro = GRPC_repro.new
repro.start
