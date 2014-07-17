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

### canner_scope

The canner_scope method is used to scope the models consistently in your app.
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

### can?

You probably recognize this method from Ryan Bates' cancan gem.  The idea is the same as well.

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

can?(:something_random, :user) would use the ... you guessed it UserPolicy's can? method.

### Force the Use of Policies

Also like Pundit you can force your app to use policies.
I recommend you do this so you don't forget to wrap authorization about some of your resources.

To make sure your controller actions are using the can? method add this to your
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

### Handle Canner Authorization Failures

When a user does stumble onto something they don't have access to you'll want to politely
tell them about it and direct the app flow as you see fit.

Do accomplish this in your application_controller.rb add

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


