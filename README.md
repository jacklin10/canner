Canner
======

Canner is an authorization gem heavily modeled after Pundit.
The goal is to take away some of the magic that exists in other auth gems out there and
provide the flexibility needed for your specific app.

Who needs another auth gem?  There's a bunch of very good ones out there.
Pundit, cancan, cancancan, Declarative Authorization to name a few very good alternatives.

Unfortunately none of those solutions had built in support for a requirement I had on a project.
My application needed to authorize a user at a given store location.

Suppose I opened a store in Pittsburgh named Joe's Hash Rockets. The word quickly got around that Joe's
hash rockets are the best in town!  Business is booming and after some market research I determine that
Cleveland is a perfect place to open another store location.

The problem is that I have some reports that only the store manager should see.
In any of the above listed gems if you have a manager role you could see all the reports regardless
of the store location aka store branch.

Canner takes this additional layer of authorization in to account.
Instead of saying:
Can the currently signed in user access this particular report.
Canner can say:
Can the currently signed in user access this particular report for this particular branch.

To do this in other libraries you might find yourself creating roles like
pittsburgh_manager and cleveland_manager.  Or maybe writing some monkey patches to hack in what you need.

Canner is designed to give you an outline of what you'll need for your app's auth needs and leaves
the level of complexity needed up to the requirements of your particular application.

## Installation

I've only tested Canner on rails 4 but it should work find in rails 3.2 apps.

To install Canner just put the following in your gem file.
``` ruby
gem "canner"
```

Then run

``` ruby
bundle install
```

After the gem is installed you'll need to run the install generator:

``` ruby
rails g canner:install
```

This will create a policies directory and create the base_policy.rb

Now include canner in your application_controller.rb

``` ruby
include Canner
```

You'll then need to create a Policy class for the models you'd like to authorize.

``` ruby
rails g canner:policy user
```

Restart your server

## Policies

As mentioned Canner is strongly influenced by Pundit and is also based on Policy objects.
Your policy objects should be named using the pattern model_namePolicy.rb.
i.e UserPolicy, CustomerPolicy, AppPolicy.

Your policy models need to implement 2 methods:
``` ruby
def canner_scope
end

def can?
end
```

### Base Policy

After you run the install generator you'll see the base_policy.rb in your app
under the policies directory.

The implemenation for these methods is up to you.  You'll find its much easier
to do than you might think, and because there isn't tons of ruby magic its more readable.

By default the base_policy takes the current user, a branch and the method (aka action).
You can easily change this to whatever you need.

If your app just does the standard validate user against an action then you can remove the
branch attribute.

If your app needs to capture more information for use with validation that's fine too.
Since you write the validation policy in plain ruby its easy to customize to suit your needs.

Canner doesn't try to tell you what you need.  It just provides a guide to allow you
to build whatever auth strategy works best for your requirements.

### fetch_roles

This method is how you feed your apps roles into canner so they can be checked against.
You'll need the roles returned in an array.  This will likely be something like:

``` ruby
def fetch_roles
  @current_user.roles
end

```

However if your role design is a little more complicated you can provide that in this method.

This is likely the only method of the 3 that you'll implement in the base_policy.  The remaining
methods will be implemented in the specific model policies.  Unless you want to default deny access in
all policies.

### canner_scope

You'll want to implement this method for each of your model policies that extend from base_policy.rb.

The canner_scope method is used to scope the authorized models consistently in your app.

For example in my app the Customers controller uses the canner_scope to
ensure only Users from the current_company are displayed.

``` ruby
class CustomersController < ApplicationController
  respond_to :html, :json
  before_action :authenticate_user!

  def index
    @customers = canner_scope(:index, :customer)

    can?(:index, :customer)
  end
end
```

and the policy is:

``` ruby
class CustomerPolicy < BasePolicy

  def canner_scope
    case @method
    when :index
      User.where(company_id: @current_branch.company.id)
    else
      User.none
    end
  end

  def can?
    case @method
    when :new, :index, :create, :update, :edit
      has_role?(:admin)
    else
      false
    end
  end

end
```

Now you don't really need to think about the auth logic when fetching a list of customers.
Just make sure you use the policy and you'll only show the users what is intended.

Also if your policy changes at some point its a one place fix.

### can?

You probably recognize this method from Ryan Bates' cancan gem.  The idea is the same as well.
You'll likely only implement this is your model policies as well.

You use the can method to determine if the current_user is able to access an action or resource.

The example above uses a straightforward case statement to determine if the current_user can
access the current action or resource.

The symbols in the when portion of the case match your typical actions in the example but they
can be whatever you want really.

``` ruby
case @method
when :something_random
  has_role?(:admin)
else
  false
end

# Then in controller do:
can?(:something_random, :customer)
```

In english the can method is saying:

Can the currently signed in user access the something_random action?  Oh, and by the way please
use the CustomerPolicy's can? method to do the checking.

`can?(:something_random, :user)` would use the ... you guessed it UserPolicy's can? method.

If you want to deny access by default across all model policies you could do something as simple as:

``` ruby
def can?
  false
end
```

in your base_policy's `can?` method

### Force the Use of Policies

Also like Pundit you can force your app to use policies.
I recommend you do this so you don't forget to wrap authorization about some of your resources.

To make sure your controller actions are using the can? method add this near the top of your
application_controller.rb

``` ruby
after_action :ensure_auth
```

And to make sure you are using the canner_scope do the following:
``` ruby
after_action :ensure_scope, only: :index
```

Note the use of only here.  You usually won't need the canner_scope on anything except
for the index to be strictly enforced.

If you would like to skip for a particular controller just add
``` ruby
skip_filter :ensure_scope
```
And / Or
``` ruby
skip_filter :ensure_auth
```

### Handle Canner Authorization Failures

When a user does stumble onto something they don't have access to you'll want to politely
tell them about it and direct the app flow as you see fit.

To accomplish this in your application_controller.rb add

``` ruby
  rescue_from Canner::NotAuthorizedError, with: :user_not_authorized
```

You can name your method whatever you want.  Mine is user_not_authorized and looks like this:

``` ruby
  private

  def user_not_authorized(exception)
    flash[:error] = exception.message
    redirect_to(request.referrer || root_path)
  end
```

### Using can? in views

You'll likely want to show or hide on screen items based on a users' role.
This is done in canner like this:

``` ruby
  = link_to 'Create Customer', new_customer_path if canner_policy(:new, :customer).can?
```

This will look in the CustomerPolicy's can? method implemention and follow whatever rules
you have for the :new symbol.

So assuming the CustomerPolicy can? method provided below the currently signed in user
would only be able to see the create customer link if they had an admin role.

``` ruby
  def can?
    case @method
    when :new
      has_role?(:admin)
    else
      false
    end
  end
```

### Testing

Testing your policies isn't very difficult and it will vary a bit from app to app so I'll
just show what I do as an example.

The app I use canner for is using minitest so the examples will be using that instead of rspec.

``` ruby

require 'test_helper'
include AuthMacros

class UserPolicyTest < ActiveSupport::TestCase

  describe UserPolicy do
    let(:current_user) {users(:joe)}
    let(:current_branch) { branches(:pittsburgh) }

    describe 'canner_scope' do

      it 'should return an empty user unless when not index method' do
        policy = UserPolicy.new(current_user, current_branch, 'show')
        assert_equal policy.canner_scope, User.none
      end

      it 'should return only users for the correct company' do
        policy = UserPolicy.new(current_user, current_branch, 'index')
        users = policy.canner_scope

        assert_equal users.size, 1

        policy = UserPolicy.new(current_user, monaca, 'index')
        users = policy.canner_scope

        assert_equal users.size, 0
      end

    end

    describe 'can?' do

      it 'should verify sysop access' do
        allowed_methods = [:new, :index, :create, :update, :edit, :lookup_user, :selected_user]

        policy_test(current_user, 'sysop', allowed_methods, 'user')
      end

    end

  end

end

```

I wrote a method ``` policy_test ``` in a module that I mix in.
This makes it pretty easy to test all my policies quickly.

I just want to make sure the policy allows access to only the actions I expect
and denies access to those I don't expect.

Here's what AuthMacro looks like:

``` ruby

module AuthMacros

  def policy_test(user, rolename, allowed_actions, model_name, branch=user.active_branch)
    all_actions = find_all_actions(model_name)

    # Yours might be something like: user.role = rolename
    user.grant!(rolename, branch)

    allowed_actions.each do |method|
      assert policy_can?(model_name, user, branch, method), "Not permitted to :#{method}, but test thinks it is"
    end

    (all_actions - allowed_actions).each do |method|
      assert_not policy_can?(model_name, user, branch, method), "Permitted to :#{method}, but test doesn't expect it"
    end

  end

  def policy_can?(model_name, user, branch, method)
    "#{model_name.classify}Policy".constantize.send(:new, user, branch, method).can?
  end

  def find_all_actions(model_name)
    "#{model_name.classify.pluralize(2)}Controller".constantize.send(:action_methods).map{|m| m.to_sym}
  end

end

```
