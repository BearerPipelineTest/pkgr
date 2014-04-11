require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::Config do
  let(:config) { Pkgr::Config.new(:version => "0.0.1", :name => "my-app", :iteration => "1234", :env => ["RACK_ENV=staging", "CURL_TIMEOUT=250"]) }

  it "is valid" do
    expect(config).to be_valid
  end

  it "is no valid if no name given" do
    config.name = ""
    expect(config).to_not be_valid
    expect(config.errors).to include("name can't be blank")
  end

  it "is not valid if invalid version number" do
    config.version = "abcd"
    expect(config).to_not be_valid
    expect(config.errors).to include("version must start with a digit")
  end

  it "exports to cli arguments" do
    config.homepage = "http://somewhere"
    config.description = "some description"
    expect(config.to_args).to include("--description \"some description\"")
    expect(config.to_args).to include("--version \"0.0.1\"")
    expect(config.to_args).to include("--name \"my-app\"")
    expect(config.to_args).to include("--user \"my-app\"")
    expect(config.to_args).to include("--group \"my-app\"")
    expect(config.to_args).to include("--architecture \"x86_64\"")
    expect(config.to_args).to include("--homepage \"http://somewhere\"")
    expect(config.to_args).to include("--env \"RACK_ENV=staging\" \"CURL_TIMEOUT=250\"")
  end

  it "can read from a config file" do
    config = Pkgr::Config.load_file(fixture("pkgr.yml"), "debian-squeeze")
    expect(config.name).to eq("some-awesome-app")
    expect(config.description).to eq("An awesome description here!")
    expect(config.user).to eq("git")
    expect(config.group).to eq("git")
    expect(config.homepage).to eq("http://example.org")
    expect(config.dependencies).to eq(["mysql-server", "git-core"])
    expect(config.build_dependencies).to eq(["libmagickcore-dev", "libmagickwand-dev"])
  end

  it "correctly recognizes yaml references" do
    config1 = Pkgr::Config.load_file(fixture("pkgr.yml"), "debian-squeeze")
    config2 = Pkgr::Config.load_file(fixture("pkgr.yml"), "ubuntu-lucid")
    expect(config1.dependencies).to eq(config2.dependencies)
  end

  it "can merge two config objects together" do
    config.dependencies = ["dep1", "dep2"]
    config2 = Pkgr::Config.load_file(fixture("pkgr.yml"), "debian-squeeze")
    new_config = config.merge(config2)

    expect(new_config.name).to eq("some-awesome-app")
    expect(new_config.home).to eq("/opt/some-awesome-app/app")
    expect(new_config.version).to eq("0.0.1")
    expect(new_config.user).to eq("git")
    expect(new_config.dependencies).to eq(["dep1", "dep2", "mysql-server", "git-core"])
    expect(new_config.build_dependencies).to eq(["libmagickcore-dev", "libmagickwand-dev"])
  end

  describe "#after_hook" do
    it "returns the content of the after_precompile option if any" do
      config.after_precompile = "path/to/hook"
      expect(config.after_hook).to eq("path/to/hook")
    end

    it "creates a tmpfile with the content of the after configuration option (if any)" do
      config.after = ["do_something", "do_something_else"]
      hook = config.after_hook
      expect(hook).to_not be_empty
      expect(File.read(hook)).to eq("do_something\ndo_something_else\n")
    end
  end

  describe "#before_hook" do
    it "returns the content of the before_precompile option if any" do
      config.before_precompile = "path/to/hook"
      expect(config.before_hook).to eq("path/to/hook")
    end

    it "creates a tmpfile with the content of the before configuration option (if any)" do
      config.before = ["do_something", "do_something_else"]
      hook = config.before_hook
      expect(hook).to_not be_empty
      expect(File.read(hook)).to eq("do_something\ndo_something_else\n")
    end
  end
end
