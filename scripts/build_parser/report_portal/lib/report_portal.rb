# Class for ReportPortal api
class ReportPortal
  require 'json'
  require 'faraday'

  API_URL = 'api/v1'.freeze
  STANDARD_FILTER_TAG = 'STANDARD_FILTER'.freeze
  STANDARD_DASHBOARD_TAG = 'STANDARD_DASHBOARD'.freeze
  STANDARD_WIDGET_TAG = 'STANDARD_WIDGET'.freeze

  def initialize(host, project_name, bearer)
    @host = "#{host}/#{API_URL}"
    @project_name = project_name
    @bearer = bearer
  end

  def create_dashboard(name, description)
    dashboard_id = get_dashboard_id_by_name(name)
    if dashboard_id.nil?
      url = "#{@host}/#{@project_name}/dashboard"
      method = :post
    else
      url = "#{@host}/#{@project_name}/dashboard/#{dashboard_id}"
      method = :put
    end

    response = make_response(
      method, url,
      'description' => add_standard_dashboard_tag(description),
      'name' => name,
      'share' => true
    )
    return dashboard_id unless dashboard_id.nil?
    JSON.parse(response.body.to_s).to_hash['id']
  end

  def add_widget_to_dashboard(dashboard_id, widget_id)
    url = "#{@host}/#{@project_name}/dashboard/#{dashboard_id}"
    response = make_response(
      :put, url,
      'addWidget' => {
        'widgetId' => widget_id,
        'widgetPosition' => [
          0
        ],
        'widgetSize' => [
          0
        ]
      }
    )
    JSON.parse(response.body.to_s).to_hash['id']
  end

  def create_widget(name, description, type, gadget, filter_id, options = {}, content_fields = [], widget_id = nil)
    if widget_id.nil?
      url = "#{@host}/#{@project_name}/widget"
      method = :post
    else
      url = "#{@host}/#{@project_name}/widget/#{widget_id}"
      method = :put
    end

    response = make_response(
      method, url,
      'content_parameters' => {
        'type' => type,
        'gadget' => gadget,
        'metadata_fields' => %w(name number start_time),
        'itemsCount' => 50,
        'widgetOptions' => options,
        'content_fields' => content_fields
      },
      'filter_id' => filter_id,
      'description' => add_standard_widget_tag(description),
      'name' => name,
      'share' => true
    )

    return widget_id unless widget_id.nil?
    JSON.parse(response.body.to_s).to_hash['id']
  end

  def create_project
    url = "#{@host}/project"
    response = make_response(
      :post, url,
      'entryType' => 'INTERNAL',
      'projectName' => @project_name
    )
    JSON.parse(response.body.to_s).to_hash['id']
  end

  def get_launch_id(name)
    url = "#{@host}/#{@project_name}/launch"
    response = make_get_response(
      url,
      'filter.eq.name' => name
    )
    launch = JSON.parse(response.body.to_s).to_hash['content'].first
    return nil if launch.nil?
    launch['id']
  end

  def get_test_id(launch_id, name)
    url = "#{@host}/#{@project_name}/item"
    response = make_get_response(
      url,
      'filter.eq.launch' => launch_id,
      'filter.eq.name' => name
    )
    test = JSON.parse(response.body.to_s).to_hash['content'].first
    return nil if test.nil?
    test['id']
  end

  def update_test(item_id, description, tags)
    url = "#{@host}/#{@project_name}/item/#{item_id}/update"
    make_response(
      :put,
      url,
      'description' => description,
      'tags' => tags
    )
  end

  def update_launch(launch_id, description, tags)
    url = "#{@host}/#{@project_name}/launch/#{launch_id}/update"
    make_response(
      :put,
      url,
      'description' => description,
      'tags' => tags
    )
  end

  def start_launch(name, mode, description, start_time, tags = [])
    launch_id = get_launch_id(name)
    unless launch_id.nil?
      update_launch(launch_id, description, tags)
      return launch_id
    end

    url = "#{@host}/#{@project_name}/launch"
    response = make_response(
      :post,
      url,
      'description' => description,
      'mode' => mode,
      'name' => name,
      'start_time' => start_time,
      'tags' => tags
    )
    JSON.parse(response.body.to_s).to_hash['id']
  end

  def finish_launch(launch_id, end_time)
    url = "#{@host}/#{@project_name}/launch/#{launch_id}/finish"
    make_response(
      :put,
      url,
      'end_time' => end_time
    )
  end

  def add_root_test_item(launch_id, name, description, params, start_time, type, tags = [], status, end_time)
    test_id = get_test_id(launch_id, name)
    unless test_id.nil?
      update_test(test_id, description, tags)
      return test_id
    end

    url = "#{@host}/#{@project_name}/item"
    response = make_response(
      :post,
      url,
      'description' => description,
      'launch_id' => launch_id,
      'name' => name,
      'parameters' => params, # [{ key: '', value: '' }, ...]
      'start_time' => start_time,
      'tags' => tags,
      'type' => type
    )
    item_id = JSON.parse(response.body.to_s).to_hash['id']

    url = "#{@host}/#{@project_name}/item/#{item_id}"
    make_response(
      :put,
      url,
      'end_time' => end_time,
      'status' => status
    )
    item_id
  end

  def add_child_test_item(launch_id, parent_item, name, description, params, start_time, type, unique_id, tags = [])
    url = "#{@host}/#{@project_name}/item/#{parent_item}"
    response = make_response(
      :post, url,
      'description' => description,
      'launch_id' => launch_id,
      'name' => name,
      'parameters' => params, # [{ key: '', value: '' }, ...]
      'start_time' => start_time,
      'tags' => tags,
      'type' => type,
      'uniqueId' => unique_id
    )
    JSON.parse(response.body.to_s).to_hash['id']
  end

  def add_filter(name, description, entities = [], is_asc = false)
    url = "#{@host}/#{@project_name}/filter"
    response = make_response(
      :post,
      url,
      'elements' => [
        {
          'name' => name,
          'description' => add_standard_filter_tag(description),
          'entities' => entities,
          'is_link' => false,
          'selection_parameters' => {
            'is_asc' => is_asc,
            'page_number' => 1,
            'sorting_column' => 'start_time'
          },
          'share' => true,
          'type' => 'launch'
        }
      ]
    )
    JSON.parse(response.body.to_s).first['id']
  end

  def all_standard_filters
    url = "#{@host}/#{@project_name}/filter"
    response = make_get_response(url)
    standard_filters = JSON.parse(response.body.to_s).to_h['content'].keep_if do |filter|
      filter['description'].include?(STANDARD_FILTER_TAG)
    end
    standard_filters
  end

  def delete_standard_filters
    url = "#{@host}/#{@project_name}/filter"
    response = make_get_response(url)
    standard_filters_ids = []
    JSON.parse(response.body.to_s).to_h['content'].each do |filter|
      if filter['description'].include?(STANDARD_FILTER_TAG)
        standard_filters_ids << filter['id']
      end
    end
    standard_filters_ids.each { |filter_id| delete_filter(filter_id) }
  end

  def get_dashboard_id_by_name(name)
    url = "#{@host}/#{@project_name}/dashboard"
    response = make_get_response(url)
    dashboard_res = JSON.parse(response.body.to_s).find do |dashboard|
      dashboard['name'] == name
    end
    return nil if dashboard_res.nil?
    dashboard_res['id']
  end

  def standard_widget?(widget_id)
    url = "#{@host}/#{@project_name}/widget/#{widget_id}"
    response = make_get_response(url)
    widget = JSON.parse(response.body.to_s)
    return false if widget.nil? || widget.to_h['description'].nil?
    widget.to_h['description'].include?(STANDARD_WIDGET_TAG)
  end

  def delete_widget_from_dashboard(dashboard_id, widget_id)
    url = "#{@host}/#{@project_name}/dashboard/#{dashboard_id}"
    make_response(:put, url, 'deleteWidget' => widget_id)
  end

  def delete_standard_widgets_from_dashboard(dashboard_id)
    url = "#{@host}/#{@project_name}/dashboard/#{dashboard_id}"
    response = make_get_response(url)
    widgets = JSON.parse(response.body.to_s).to_h['widgets']
    return if widgets.nil?
    widgets.each do |widget|
      if standard_widget?(widget['widgetId'])
        delete_widget_from_dashboard(dashboard_id, widget['widgetId'])
      end
    end
  end

  def delete_filter(filter_id)
    url = "#{@host}/#{@project_name}/filter/#{filter_id}"
    make_response(:delete, url)
  end

  private

  def add_standard_filter_tag(description)
    "#{description}\n\n#{STANDARD_FILTER_TAG}"
  end

  def add_standard_dashboard_tag(description)
    "#{description}\n\n#{STANDARD_DASHBOARD_TAG}"
  end

  def add_standard_widget_tag(description)
    "#{description}\n\n#{STANDARD_WIDGET_TAG}"
  end

  def make_response(method, url, body = {})
    Faraday.new.send(method) do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
      req.headers['Authorization'] = "bearer #{@bearer}"
      req.body = body.to_json.to_s
    end
  end

  def make_get_response(url, params = {})
    Faraday.new.get do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
      req.headers['Authorization'] = "bearer #{@bearer}"
      req.params = params
    end
  end
end
