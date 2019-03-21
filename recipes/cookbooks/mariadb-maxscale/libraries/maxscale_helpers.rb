module MaxScale
  MAX_SCALE_VERSION = /(\d+\.)(\d+\.)?(\*|\d+)/

  # Check whether MaxScale that is being installed is older than the specified version
  # @param installed_version [String] version of the MaxScale being installed
  # @param target_version [String] the version to check
  # @return [Boolean] whether current version is older than the target version
  def self.is_older_than?(installed_version, target_version)
    return false unless installed_version =~ MAX_SCALE_VERSION

    current_version_parts = MAX_SCALE_VERSION.match(installed_version)[0].split('.').map(&:to_i)
    target_version_parts = target_version.split('.').map(&:to_i)
    current_version_iterator = current_version_parts.each
    target_version_iterator = target_version_parts.each
    loop do
      check = current_version_iterator.next <=> target_version_iterator.next
      next if check == 0
      return check < 0
    end

    false
  end
end
