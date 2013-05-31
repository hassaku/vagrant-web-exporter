require 'open3'
require 'lib/vm'
require 'lib/vagrant_exporter'

class App < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  get '/style.css' do
    content_type 'text/css', :charset => 'utf-8'
    scss :style
  end

  # filter
  before do
    pass if ["", "instruction"].include? request.path_info.split('/')[1]

    #TODO: バックグランド実行で作られるファイルだから、creatingの状態を示すのに向かない...
    #Vm.all.each do |vm|
      #vm.destroy unless File.exist?("public/packages/#{vm.name}.box")
      #vm.destroy unless File.exist?("public/shared_folders/#{vm.name}.tar.gz")
    #end

    # create record on memory from virtualbox name
    Vm.vbox_names.each do |vbox_name|
      #Vm.where(vbox_name: vbox_name).first_or_create!
      Vm.create!({vbox_name: vbox_name}) unless Vm.find_by_vbox_name(vbox_name)
    end
  end

  get '/' do
    @vms = Vm.all
    haml :index
  end

  get '/instruction/:package_name' do
    `/sbin/ifconfig`.scan(/.*inet (192\.\d+\.\d+\.\d+) .*/i)
    url = "http://#{$1}:#{request.port}"

    vagrant = VagrantExporter.new(settings.vagrant_root)
    @instruction = vagrant.instruction(params[:package_name], url)
    haml :instruction
  end

  #TODO: should be POST
  get '/package/:package_name' do
    vagrant = VagrantExporter.new(settings.vagrant_root)
    vagrant.export(params[:package_name])

    vm = Vm.find_by_name(params[:package_name])
    vm.creating = true
    vm.save!
    #vm.update_status
    p Vm.find_by_name(params[:package_name])

    redirect '/' ## すぐレスポンス返す
  end

end

