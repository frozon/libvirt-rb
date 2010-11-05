require "test_helper"

Protest.describe("connection") do
  setup do
    @klass = Libvirt::Connection
  end

  context "connecting" do
    should "connect and return a connection" do
      result = nil
      assert_nothing_raised { result = @klass.connect("test:///default") }
      assert result.is_a?(@klass)
    end

    should "raise an exception if the connection fails" do
      assert_raise(Libvirt::Exception::LibvirtError) {
        @klass.connect("thisshouldneverpass:)")
      }
    end
  end

  context "with a valid connection" do
    setup do
      @cxn = @klass.connect("test:///default")
    end

    should "provide the library version" do
      # We rely on virsh to get the version of libvirt
      version = @cxn.lib_version
      actual = `virsh --version`.chomp.split(".").map { |s| s.to_i }
      assert_equal actual, version
    end

    should "provide the capabilities of the connection" do
      assert_nothing_raised { @cxn.capabilities }
    end

    should "provide the hostname of the connection" do
      assert_nothing_raised { @cxn.hostname }
    end

    should "provide the uri of the connection" do
      result = nil
      assert_nothing_raised { result = @cxn.uri }
      assert_equal "test:///default", result
    end

    should "provide the type of the connection" do
      result = nil
      assert_nothing_raised { result = @cxn.type }
      assert_equal "Test", result
    end

    should "provide the hypervisor version of the connection" do
      result = nil
      assert_nothing_raised { result = @cxn.hypervisor_version }
      assert_equal [0,0,2], result
    end

    should "provide a list of domains" do
      result = nil
      assert_nothing_raised { result = @cxn.domains }
      assert result.is_a?(Array)
      assert_equal 1, result.length
      assert result.first.is_a?(Libvirt::Domain)
    end

    context "defining a new domain" do
      setup do
        @spec = Libvirt::Spec::Domain.new
        @spec.hypervisor = :test
        @spec.name = "My Test VM"
        @spec.os.type = :hvm
        @spec.memory = 123456 # KB
      end

      should "create the new domain when the specification is valid" do
        result = nil
        assert_nothing_raised { result = @cxn.define_domain(@spec) }
        assert result.is_a?(Libvirt::Domain)
        assert !result.active?
        assert_equal @spec.name, result.name
      end

      should "raise an error when the specification is not valid" do
        @spec.hypervisor = nil
        assert_raise(Libvirt::Exception::LibvirtError) {
          @cxn.define_domain(@spec)
        }
      end
    end
  end
end
