require 'open3'
require_relative 'helper'
require_relative 'session'

class DockerManager

  DOCKER_IMAGES_CMD = 'docker images'
  DOCKER_BUILD_CMD = 'docker build'

  # @image_name - string PLATFORM:PLATFORM_VERSION
  def DockerManager.image_exists(image_name)
    images_output = `#{DOCKER_IMAGES_CMD}`
    raise 'Can not get docker images (check docker daemon)' if $?.exitstatus != 0
    images_lines = images_output.split "\n"
    if images_lines.length > 1
      images = Array.new
      (1..images_lines.length - 1).each do |i|
        repository = images_lines[i].split(/\s+/)[0]
        images.push repository
      end
      return images.include? image_name
    else
      return false
    end
  end

  def DockerManager.build_image(dockerfile_directory, image_name)
    if !image_exists(image_name)
      $out.info "Starting building docker image #{image_name} from Dockerfile: #{dockerfile_directory}"
      execute_bash("#{DOCKER_BUILD_CMD} -t #{image_name} #{dockerfile_directory}")
    else
      $out.info "Docker image #{image_name} already exists (Dockerfile here #{dockerfile_directory})"
    end
  end

end