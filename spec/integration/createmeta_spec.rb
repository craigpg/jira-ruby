require 'spec_helper'

describe JIRA::Resource::Createmeta do

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { "10000" }

    let(:expected_attributes) do
      {
        'self' => "http://localhost:2990/jira/rest/api/2/project/10000",
        'id'   => key,
        'name' => 'SAMPLEPROJECT'
      }
    end

    let(:expected_collection_length) { 1 }

    it_should_behave_like "a resource"
    it_should_behave_like "a resource with a collection GET endpoint"

  end
end
