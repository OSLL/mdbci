packages_list = %w[
  libssl-dev
]
packages_list.each do |pkg|
  package pkg do
    retries 2
    retry_delay 10
    ignore_failure true
  end
end
