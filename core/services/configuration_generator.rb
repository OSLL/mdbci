# frozen_string_literal: true

# The class provides methods for generating the role of the file.
class ConfigurationGenerator
  # Generate a list of role parameters in JSON format
  # @param box_definitions [BoxDefinitions] the list of BoxDefinitions that are configured in the application
  # @param name [String] node name
  # @param product_config [Hash] list of the product parameters
  # @param recipe_name [String] name of the recipe
  # @param box [String] name of the box
  # @param rhel_credentials redentials for subscription manager
  def self.generate_json_format(box_definitions, name, product_configs, recipes_names, box, rhel_credentials)
    run_list = ['recipe[mdbci_provision_mark::remove_mark]',
                *recipes_names.map { |recipe_name| "recipe[#{recipe_name}]" },
                'recipe[mdbci_provision_mark::default]']
    if check_subscription_manager(box_definitions, box)
      raise 'RHEL credentials for Red Hat Subscription-Manager are not configured' if rhel_credentials.nil?

      run_list.insert(1, 'recipe[subscription-manager]')
      product_configs = product_configs.merge('subscription-manager': rhel_credentials)
    end
    role = { name: name,
             default_attributes: {},
             override_attributes: product_configs,
             json_class: 'Chef::Role',
             description: '',
             chef_type: 'role',
             run_list: run_list }
    JSON.pretty_generate(role)
  end

  # Check whether box needs to be subscribed or not
  # @param box_definitions [BoxDefinitions] the list of BoxDefinitions that are configured in the application
  # @param box [String] name of the box
  def self.check_subscription_manager(box_definitions, box)
    box_definitions.get_box(box)['configure_subscription_manager'] == 'true'
  end

  # Generate the list of the product parameters
  # @param repos [RepoManager] for products
  # @param product_name [String] name of the product for install
  # @param product [Hash] parameters of the product to configure from configuration file
  # @param box [String] name of the box
  # @param repo [String] repo for product
  def self.generate_product_config(repos, product_name, product, box, repo)
    repo = repos.find_repository(product_name, product, box) if repo.nil?
    raise "Repo for product #{product['name']} #{product['version']} for #{box} not found" if repo.nil?

    config = { 'version': repo['version'], 'repo': repo['repo'], 'repo_key': repo['repo_key'] }
    if check_product_availability(product)
      config['cnf_template'] = product['cnf_template']
      config['cnf_template_path'] = product['cnf_template_path']
    end
    repo_file_name = repos.repo_file_name(product_name)
    config['repo_file_name'] = repo_file_name unless repo_file_name.nil?
    config['node_name'] = product['node_name'] unless product['node_name'].nil?
    attribute_name = repos.attribute_name(product_name)
    { "#{attribute_name}": config }
  end

  # Checks the availability of product information.
  # @param product [Hash] parameters of the product to configure from configuration file
  def self.check_product_availability(product)
    !product['cnf_template'].nil? && !product['cnf_template_path'].nil?
  end
end
