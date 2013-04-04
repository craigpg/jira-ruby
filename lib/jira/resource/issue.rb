require 'cgi'

module JIRA
  module Resource

    class IssueFactory < JIRA::BaseFactory # :nodoc:
    end

    class Issue < JIRA::Base

      # pagination constants
      PAGE_SIZE            = 500
      DEFAULT_MAX_RESULTS  = 50

      has_one :reporter,  :class => JIRA::Resource::User,
                          :nested_under => 'fields'
      has_one :assignee,  :class => JIRA::Resource::User,
                          :nested_under => 'fields'
      has_one :project,   :nested_under => 'fields'

      has_one :issuetype, :nested_under => 'fields'

      has_one :priority,  :nested_under => 'fields'

      has_one :status,    :nested_under => 'fields'

      has_many :components, :nested_under => 'fields'

      has_many :comments, :nested_under => ['fields','comment']

      has_many :attachments, :nested_under => 'fields',
                          :attribute_key => 'attachment'

      has_many :versions, :nested_under => 'fields'

      has_many :worklogs, :nested_under => ['fields','worklog']

      def self.get(client, params = {})
        url = client.options[:rest_base_path] + "/search"
        client.post(url, params.to_json)
      end

      def self.get_issues(client, params = {})
        json = parse_json(get(client, params).body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

      def self.all(client, params = {})
        max_results = params[:maxResults] || DEFAULT_MAX_RESULTS
        start_at = params[:startAt] || 0
        page_size = [max_results, PAGE_SIZE].min
        [].tap do |results|
          while (results.size < max_results) do
            results_page = get_issues(client, params.merge(:maxResults => [page_size, max_results - results.size].min,
                                                           :startAt    => start_at + results.size))
            break if results_page.empty?
            results.concat(results_page)
            break if results_page.size < page_size
          end
        end
      end

      def self.jql(client, jql, params = {})
        all(client, params.merge(:jql => jql))
      end

      def respond_to?(method_name)
        if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &block)
        if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
          attrs['fields'][method_name.to_s]
        else
          super(method_name)
        end
      end

    end

  end
end
