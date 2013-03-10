module JIRA
  module Resource

    class CreatemetaFactory < JIRA::BaseFactory # :nodoc:
    end

    class Createmeta < JIRA::Base
      def self.endpoint_name
        'issue/createmeta'
      end

      def self.all(client, params = {})
        url = params.empty? ? collection_path(client) : [collection_path(client), URI.encode_www_form(params)].join('?')
        response = client.get(url)
        json = parse_json(response.body)
        json['projects'].map do |project|
          client.Createmeta.build(project)
        end
      end
    end
  end
end
