require 'test_helper'

describe WorksController do
  describe "root" do
    it "succeeds with all media types" do
      # Precondition: there is at least one media of each category
      %w(album book movie).each do |category|
        Work.by_category(category).length.must_be :>, 0, "No #{category.pluralize} in the test fixtures"
      end

      get root_path
      must_respond_with :success
    end

    it "succeeds with one media type absent" do
      # Precondition: there is at least one media in two of the categories
      %w(album book).each do |category|
        Work.by_category(category).length.must_be :>, 0, "No #{category.pluralize} in the test fixtures"
      end

      # Remove all movies
      Work.by_category("movie").destroy_all

      get root_path
      must_respond_with :success
    end

    it "succeeds with no media" do
      Work.destroy_all
      get root_path
      must_respond_with :success
    end
  end

  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

  describe "index" do
    it "will redirect_to root if not logged in" do
      get works_path
      must_redirect_to root_path
    end

    describe "logged-in" do
      before do
        login(users(:dan))
      end

      it "succeeds when there are works" do
        Work.count.must_be :>, 0, "No works in the test fixtures"
        get works_path
        must_respond_with :success
      end

      it "succeeds when there are no works" do
        Work.destroy_all
        get works_path
        must_respond_with :success
      end
    end
  end

  describe "new" do
    it "should work if you are logged in" do
      login(users(:dan))
      get new_work_path
      must_respond_with :success
    end

    it "should redirect_to root if you are not logged in" do
      get new_work_path
      must_redirect_to root_path
    end
  end

  describe "create" do
    it "will redirect_to root if not logged in and not create work" do
      work_data = {
        work: {
          title: "test work",
          category: CATEGORIES.first
        }
      }
      start_count = Work.count

      post works_path(CATEGORIES.first), params: work_data
      must_redirect_to root_path

      Work.count.must_equal start_count
    end

    describe "logged-in" do
      before do
        login(users(:dan))
      end

      it "creates a work with valid data for a real category" do
        work_data = {
          work: {
            title: "test work",
            user_id: users(:dan).id
          }
        }
        CATEGORIES.each do |category|
          work_data[:work][:category] = category

          start_count = Work.count

          post works_path, params: work_data
          must_redirect_to work_path(Work.last)

          Work.count.must_equal start_count + 1
        end
      end

      it "created work should assign the logged in user" do
        work_data = {
          work: {
            title: "test work",
            category: CATEGORIES.first,
            user_id: users(:dan).id
          }
        }
        start_count = Work.count

        post works_path, params: work_data
        must_redirect_to work_path(Work.last)

        Work.count.must_equal start_count + 1
        Work.last.user.must_equal users(:dan)
      end

      it "can not create a work without a user" do
        work_data = {
          work: {
            title: "test work",
            category: CATEGORIES.first
          }
        }
        start_count = Work.count

        post works_path, params: work_data
        must_respond_with :bad_request

        Work.count.must_equal start_count
      end

      it "renders bad_request and does not update the DB for bogus data" do
        work_data = {
          work: {
            title: ""
          }
        }
        CATEGORIES.each do |category|
          work_data[:work][:category] = category

          start_count = Work.count

          post works_path(category), params: work_data
          must_respond_with :bad_request

          Work.count.must_equal start_count
        end
      end

      it "renders 400 bad_request for bogus categories" do
        work_data = {
          work: {
            title: "test work"
          }
        }
        INVALID_CATEGORIES.each do |category|
          work_data[:work][:category] = category

          start_count = Work.count

          post works_path(category), params: work_data
          must_respond_with :bad_request

          Work.count.must_equal start_count
        end
      end
    end
  end

  describe "show" do
    it "will redirect_to root if not logged in" do
      get works_path
      must_redirect_to root_path
    end

    describe "logged-in" do
      before do
        login(users(:dan))
      end

      it "succeeds when you looking for your own work" do
        get work_path(works(:mariner_dan))
        must_respond_with :success
      end

      it "succeeds when you looking at someone else's work" do
        get work_path(works(:thrill_kari))
        must_respond_with :success
      end

      it "renders 404 not_found for a bogus work ID" do
        bogus_work_id = Work.last.id + 1
        get work_path(bogus_work_id)
        must_respond_with :not_found
      end
    end
  end

  describe "edit" do
    it "will redirect_to root if not logged in" do
      get edit_work_path(Work.first)
      must_redirect_to root_path
    end

    describe "logged-in" do
      before do
        login(users(:dan))
      end

      it "succeeds for an exact work ID" do
        get edit_work_path(Work.first)
        must_respond_with :success
      end

      it "renders 404 not_found for a bogus work ID" do
        bogus_work_id = Work.last.id + 1
        get edit_work_path(bogus_work_id)
        must_respond_with :not_found
      end

      it "should redirect to work_path if logged in user is not the owner" do
        get edit_work_path(works(:thrill_kari))
        must_redirect_to work_path(works(:thrill_kari))
      end
    end
  end

  describe "update" do
    it "will redirect_to root if not logged in and not update work" do
      work = works(:mariner_dan)
      work_data = {
        work: {
          title: work.title + " addition"
        }
      }
      original_title = work.title
      patch work_path(work), params: work_data
      must_redirect_to root_path

      # Verify the DB was really modified
      Work.find(work.id).title.must_equal original_title
    end

    describe "logged-in" do
      before do
        login(users(:dan))
      end

      it "succeeds for valid data and an existing work ID" do
        work = works(:mariner_dan)
        work_data = {
          work: {
            title: work.title + " addition"
          }
        }

        patch work_path(work), params: work_data
        must_redirect_to work_path(work)

        # Verify the DB was really modified
        Work.find(work.id).title.must_equal work_data[:work][:title]
      end

      it "renders bad_request for bogus data" do
        work = works(:mariner_dan)
        work_data = {
          work: {
            title: ""
          }
        }

        patch work_path(work), params: work_data
        must_respond_with :not_found

        # Verify the DB was not modified
        Work.find(work.id).title.must_equal work.title
      end

      it "renders 404 not_found for a bogus work ID" do
        bogus_work_id = Work.last.id + 1
        get work_path(bogus_work_id)
        must_respond_with :not_found
      end

      it "should not update if you don't own the work" do
        work = works(:thrill_kari)
        work_data = {
          work: {
            title: work.title + " addition"
          }
        }
        original_title = work.title
        patch work_path(work), params: work_data
        must_redirect_to work_path(work)

        # Verify the DB was really modified
        Work.find(work.id).title.must_equal original_title
      end
    end
  end

  describe "destroy" do
    it "will redirect_to root if not logged in and not delete work" do
      work_id = Work.first.id

      delete work_path(work_id)
      must_redirect_to root_path

      Work.find_by(id: work_id).wont_be_nil
    end

    describe "logged in" do
      before do
        login(users(:dan))
      end

      it "succeeds when deleting your own work" do
        work_id = works(:poodr_dan)

        delete work_path(work_id)
        must_redirect_to root_path

        # The work should really be gone
        Work.find_by(id: work_id).must_be_nil
      end

      it "renders 404 not_found and does not update the DB for a bogus work ID" do
        start_count = Work.count

        bogus_work_id = Work.last.id + 1
        delete work_path(bogus_work_id)
        must_respond_with :not_found

        Work.count.must_equal start_count
      end

      it "fails when deleting someone else's work" do
        work_id = works(:thrill_kari)

        delete work_path(work_id)
        must_redirect_to work_path(works(:thrill_kari))

        # The work should really be gone
        Work.find_by(id: work_id).wont_be_nil
      end
    end
  end

  describe "upvote" do
    let(:user) { users(:dan) }
    let(:work) { works(:movie_dan_no_votes) }

    def logout
      post logout_path
      must_respond_with :redirect
    end

    it "should redirect to the main page if not logged in" do
      start_vote_count = work.votes.count

      post upvote_path(work)
      must_redirect_to root_path

      work.votes.count.must_equal start_vote_count
    end

    it "should redirect to the main page if user logged out" do
      start_vote_count = work.votes.count

      login(user)
      logout

      post upvote_path(work)
      must_redirect_to root_path

      work.votes.count.must_equal start_vote_count
    end

    it "succeeds for a logged-in user and a fresh user-vote pair" do
      start_vote_count = work.votes.count

      login(user)

      post upvote_path(work)
      # Should be a redirect_back
      must_respond_with :redirect

      work.reload
      work.votes.count.must_equal start_vote_count + 1
    end

    it "returns 409 conflict if the user has already voted for that work" do
      login(user)
      must_redirect_to root_path

      Vote.create!(user: user, work: work)

      start_vote_count = work.votes.count

      post upvote_path(work)
      must_respond_with :conflict

      work.votes.count.must_equal start_vote_count
    end
  end
end
