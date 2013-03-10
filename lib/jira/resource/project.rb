module JIRA
  module Resource

    class ProjectFactory < JIRA::BaseFactory # :nodoc:
    end

    class Project < JIRA::Base

      has_one :lead, :class => JIRA::Resource::User
      has_many :components
      has_many :issuetypes, :attribute_key => 'issueTypes'
      has_many :versions

      def self.key_attribute
        :key
      end

      # Returns all the issues for this project
      def issues(params = {})
        params[:jql] = params.include?(:jql) ? "(#{params[:jql]}) AND (project = #{key})" : "project = #{key}"
        client.Issue.all(params)
      end

      def fields_for_issuetype_by_name(issuetype_name)
        {}.tap {|h| fields_for_issuetype(issuetype_name).each {|k,v| h[v['name']] = v.merge('fieldName' => k)}}
      end

      def fields_for_issuetype(issuetype_name)
        (createmeta_for_issuetype(issuetype_name).first.issuetypes.first || {})['fields'] || {}
      end
      
      def createmeta_for_issuetype(issuetype_name)
        client.Createmeta.all(:issuetypeNames => issuetype_name, :projectKeys => key, :expand => 'projects.issuetypes.fields')
      end

    end

  end
end
