require 'spec_helper'

def paged_mock_results(total, max_results)
  page_size = JIRA::Resource::Issue::PAGE_SIZE
  num_results = [total, max_results].min
  (0..(num_results / page_size)).map do |page_num|
    {
      :expand => "schema,names",
      :startAt => page_num * page_size,
      :maxResults => max_results,
      :total => total,
      :issues => [].tap do |h| 
        [total - page_num * page_size, page_size].min.times do |i|
          h << { "id" => (i + 1000).to_s,
                 "self" => "http://localhost:2990/jira/rest/api/2/issue/#{i + 1000}",
                 "fields" => {} }
        end
      end
    }
  end.flatten
end

describe JIRA::Resource::Issue do

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }


    let(:key) { "10002" }

    let(:expected_attributes) do
      {
        'self'   => "http://localhost:2990/jira/rest/api/2/issue/10002",
        'key'    => "SAMPLEPROJECT-1",
        'expand' => "renderedFields,names,schema,transitions,editmeta,changelog"
      }
    end

    let(:attributes_for_post) {
      { 'foo' => 'bar' }
    }
    let(:expected_attributes_from_post) {
      { "id" => "10005", "key" => "SAMPLEPROJECT-4" }
    }

    let(:attributes_for_put) {
      { 'foo' => 'bar' }
    }
    let(:expected_attributes_from_put) {
      { 'foo' => 'bar' }
    }
    let(:expected_collection_length) { 11 }

    it_should_behave_like "a resource"
    it_should_behave_like "a resource with a singular GET endpoint"
    describe "GET all issues" do # JIRA::Resource::Issue.all uses the search endpoint
      let(:client) { client }
      let(:site_url) { site_url }

      let(:expected_attributes) {
        {
          "id"=>"10014",
          "self"=>"http://localhost:2990/jira/rest/api/2/issue/10014",
          "key"=>"SAMPLEPROJECT-13"
        }
      }
      before(:each) do
        stub_request(:get, site_url + "/jira/rest/api/2/search").
                    to_return(:status => 200, :body => get_mock_response('issue.json'))
      end
      let (:paging_params) {
        {
          :maxResults => 50,
          :startAt => 0
        }
      }
      it_should_behave_like "a resource with a collection POST endpoint that retrieves pages of items"
    end
    it_should_behave_like "a resource with a DELETE endpoint"
    it_should_behave_like "a resource with a POST endpoint"
    it_should_behave_like "a resource with a PUT endpoint"
    it_should_behave_like "a resource with a PUT endpoint that rejects invalid fields"

    describe "errors" do
      before(:each) do
        stub_request(:get,
                    site_url + "/jira/rest/api/2/issue/10002").
                    to_return(:status => 200, :body => get_mock_response('issue/10002.json'))
        stub_request(:put, site_url + "/jira/rest/api/2/issue/10002").
                    with(:body => '{"missing":"fields and update"}').
                    to_return(:status => 400, :body => get_mock_response('issue/10002.put.missing_field_update.json'))
      end

      it "fails to save when fields and update are missing" do
        subject = client.Issue.build('id' => '10002')
        subject.fetch
        subject.save('missing' => 'fields and update').should be_false
      end

    end

    describe "GET jql issues" do # JIRA::Resource::Issue.jql uses the search endpoint
      jql_query_string = "PROJECT = 'SAMPLEPROJECT'"
      let(:client) { client }
      let(:site_url) { site_url }
      let(:jql_query_string) { jql_query_string }

      let(:expected_attributes) {
        {
          "id"=>"10014",
          "self"=>"http://localhost:2990/jira/rest/api/2/issue/10014",
          "key"=>"SAMPLEPROJECT-13"
        }
      }
      let (:paging_params) {
        {
          :maxResults => 50,
          :startAt => 0
        }
      }
      describe "a resource with JQL inputs and a collection POST endpoint that retrieves paginated items" do
        page_size = JIRA::Resource::Issue::PAGE_SIZE
        describe "when max results exceeds the number of issues" do
          max_results = 10000
          [1, 100, 600, 1010, 999, 9, 6034, 0].each do |num_issues|
            it "should get a collection of #{num_issues} issue(s) one page at a time" do
              results = paged_mock_results(num_issues, max_results)
              results.each_with_index do |result, i|
                stub_request(:post, site_url + client.options[:rest_base_path] + '/search').
                             with(:body => {:maxResults => page_size, :jql => jql_query_string, :startAt => (i * page_size)}.to_json,
                                  :headers => {'Accept'=>'application/json'}).
                             to_return(:status => 200, :body => result.to_json)
              end
              collection = build_receiver.jql(jql_query_string, :maxResults => max_results)
              collection.length.should == results.inject(0) {|t, r| t + r[:issues].size}
              if (num_issues == 0)
                collection.first.should be_nil
              else
                collection.first.should have_attributes(results.first[:issues].first)
                collection.last.should have_attributes(results.last[:issues].last)
              end
            end
          end
        end

        describe "when max results is less than page size" do
          page_size = JIRA::Resource::Issue::PAGE_SIZE
          max_results = page_size - 1
          num_issues = page_size * 2
          it "should get a collection of #{num_issues} issue(s)" do
            results = paged_mock_results(num_issues, max_results)
            results.each_with_index do |result, i|
              stub_request(:post, site_url + client.options[:rest_base_path] + '/search').
                           with(:body => {:maxResults => max_results, :jql => jql_query_string, :startAt => (i * page_size)}.to_json,
                                :headers => {'Accept'=>'application/json'}).
                           to_return(:status => 200, :body => result.to_json)
            end
            collection = build_receiver.jql(jql_query_string, :maxResults => max_results)
            collection.length.should == results.inject(0) {|t, r| t + r[:issues].size}
            collection.first.should have_attributes(results.first[:issues].first)
            collection.last.should have_attributes(results.last[:issues].last)
          end
        end
      end
    end

  end
end
