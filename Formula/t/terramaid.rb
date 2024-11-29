class Terramaid < Formula
  desc "Utility for generating Mermaid diagrams from Terraform configurations"
  homepage "https://github.com/RoseSecurity/Terramaid"
  url "https://github.com/RoseSecurity/Terramaid/archive/refs/tags/v2.0.2.tar.gz"
  sha256 "1ddf7f16d12e96b3169f92e78415337d76edee9e9576b03f7b844615cb2daaee"
  license "Apache-2.0"
  head "https://github.com/RoseSecurity/Terramaid.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "1b229084543b26dddea49f61cd0f2b650aeda21bf75f2ce0cfdca6c4c8efaa61"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "1b229084543b26dddea49f61cd0f2b650aeda21bf75f2ce0cfdca6c4c8efaa61"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "1b229084543b26dddea49f61cd0f2b650aeda21bf75f2ce0cfdca6c4c8efaa61"
    sha256 cellar: :any_skip_relocation, sonoma:        "686a468a164909702734a5a5f559c7b4430c39d4be520da16fbf0a716e2b903f"
    sha256 cellar: :any_skip_relocation, ventura:       "686a468a164909702734a5a5f559c7b4430c39d4be520da16fbf0a716e2b903f"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "8c3a908d95845f0187f40b611f2788c72575be6d6159fcee30ecd272578bcc4e"
  end

  depends_on "go" => [:build, :test]

  def install
    ldflags = "-s -w -X github.com/RoseSecurity/terramaid/cmd.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"terramaid", "completion")
  end

  test do
    resource "terraform" do
      # https://www.hashicorp.com/blog/hashicorp-adopts-business-source-license
      # Do not update terraform, it switched to the BUSL license
      # Waiting for https://github.com/runatlantis/atlantis/issues/3741
      url "https://github.com/hashicorp/terraform/archive/refs/tags/v1.5.7.tar.gz"
      sha256 "6742fc87cba5e064455393cda12f0e0241c85a7cb2a3558d13289380bb5f26f5"
    end

    resource("terraform").stage do
      system "go", "build", *std_go_args(ldflags: "-s -w", output: testpath/"terraform")
    end

    ENV.prepend_path "PATH", testpath

    (testpath/"main.tf").write <<~HCL
      resource "aws_instance" "example" {
        ami           = "ami-0c55b159cbfafe1f0"
        instance_type = "t2.micro"
      }
    HCL

    system bin/"terramaid", "run", "-w", testpath.to_s, "-o", testpath/"output.mmd"
    assert_predicate testpath/"output.mmd", :exist?

    assert_match version.to_s, shell_output("#{bin}/terramaid version")
  end
end
