require 'open3'

class Vm < SuperModel::Base
  attributes :name, :vbox_name, :status, :creating, :ready

  before_create :set_name, if: -> { self.vbox_name.present? }
  before_create :update_status
  before_update :update_status

  def self.vbox_names
    list, error = Open3.capture3("VBoxManage list vms")
    raise "error: #{error}" unless error.empty?
    list.split("\n")
  end

  def update_status
    if packaged?
      boxname = File.atime("public/packages/" + self.name + ".box")
      self.status = "already created. (#{boxname})"
      self.ready = true
      self.creating = false
    elsif self.creating
      self.status = "preparing now...\naccess again in a few minutes later!"
      self.ready = false
    else
      self.status = "not created yet."
      self.ready = false
    end
    true
  end

  private

  def packaged?
    Dir::entries("public/packages").include?(self.name + ".box")
  end

  def set_name
    self.name = self.vbox_name.match(/\"(.*)\"/)[0].delete("\"").gsub(/_\d+$/, "")
  end
end
