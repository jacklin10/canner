## Canner

[![Code Climate](https://codeclimate.com/github/jacklin10/canner/badges/gpa.svg)](https://codeclimate.com/github/jacklin10/canner)
[![Build Status](https://travis-ci.org/jacklin10/canner.svg?branch=master)](https://travis-ci.org/jacklin10/canner)
[![Gem Version](https://badge.fury.io/rb/canner.svg)](http://badge.fury.io/rb/canner)

Canner is an authorization gem heavily modeled after Pundit.  

Canner's intention is to provide you a framework for authorization that has little to no magic.  
Your canner policies can be as simple or as complicated as your app requires.

Who needs another auth gem?  There's a bunch of very good ones out there.  
Pundit, cancan, cancancan and Declarative Authorization to name a few alternatives.  

Unfortunately for me, none of those solutions had built in support for a requirement I had.

I needed to authorize a user by more than just a role, I needed to authorize a user by role and location.  
The other auth libraries out there don't support this requirement out of the box. 

With canner you can ask:  Can *joe* having the role *manager* access the reports for the *pittsburgh* store.  

You just have to let canner know the branch you are currently operating on.  

For details see the wiki page [Authorize with Branches ( Store Locations )](https://github.com/jacklin10/canner/wiki/Authorize-with-Branches)

Also note that canner works fine if you don't need this particular feature, its just there if you do.

## Compatability 
Canner works with rails 4.x and 5.x.

## Installation

I've only tested Canner on rails 4 but it should work fine in rails 3.2 apps.

To install Canner just put the following in your gem file.
``` ruby
gem "canner"
```

Then run

``` ruby
bundle install
```

Now include canner in your application_controller.rb

``` ruby
include Canner
```

You'll then need to create a Policy class for the models you'd like to authorize.

``` ruby
rails g canner:policy user
```

If your app gets roles from a user in a way other than ```@current_user.roles``` then you'll
need to override the fetch_roles policy method.

```ruby
rails g canner:fetch_roles
```

More details are available in the wiki:
[Overriding the Fetching of Roles](https://github.com/jacklin10/canner/wiki/Feed-Roles)

## Policies

As mentioned Canner is strongly influenced by Pundit and is also based on Policy objects.
Your policy objects should be named using the following pattern:   
```
  <model_name>Policy.rb
  i.e:  User.rb / UserPolicy.rb, Customer.rb / CustomerPolicy.rb
```

#### Generator

You can also use our generator to create the policy for you: 

``` rails g canner:policy <model name> ```

Your policy models need to implement 2 methods:

``` ruby
def canner_scope
end

def can?
end
```

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
      User.where(company_id: @current_branch.company_id)
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

You use the can? method to determine if the current_user is able to access an action or resource.

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
```
Then in controller do:
```can?(:something_random, :customer)```

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

### instance_can?

You use the instance_can? method to determine if the current_user is able to modify a particular instance
of an object.  

For example, if a user wants to edit a particular item they may end up here:  

```
/items/3/edit
```

The user changes the item price and moves on with their day.

Now we have another user who decides they want to see what happens if they tinker with the url to potential edit other items.
They enter the following:

```
/items/13/edit
```

Maybe item 13 belongs to a different company, or is in a cateogory that this user isn't supposed to see.
If you don't defend against this situation a clever user can gain access to any item in the system.

The **instance_can?** method helps in these situations.  

In your items controller for the **edit, update and destroy** methods add something like:  

``` ruby
@item = Item.find params[:id]
instance_can? :manage, :item, @item
```

Your item_policy.rb will have something like:  

``` ruby
def instance_can?(item)
  case @method
  when :manage
    return @current_user.item_categories.include?(item.category)
  else
    false
  end
end
```

Now an access denied message will be shown to any users attempting to access an item in a category they don't belong to.

Your policy can be more complex if needed.  Canner is just a framework so you can get as creative as you want
just so long as you eventually return true or false.  

For example, maybe your admin user is allowed to edit any items?  You could do something like this:  
``` ruby
def instance_can?(item)
  case @method
  when :manage
    return has_role?(:admin) ? true : @current_user.company == item.company
  else
    false
  end
end
```

You can enforce that your methods check for this just like you can for ```canner_scope``` or ```can?```.  
The next section shows you how.

### Forcing Controller Authorization

You are able to force the use of controller authorization with canner.  
I recommend you do this so you don't forget to wrap authorization about some of your resources.

To make sure your controller actions are using the can? method add this near the top of your
`application_controller.rb`.  Use the `unless:` option for ensuring we ignore controllers
related to authentication.

``` ruby
after_action :ensure_auth

# using devise?
after_action :ensure_auth, unless: :devise_controller?

# using CASino?
after_action :ensure_auth, unless: -> { self.is_a? CASino::SessionsController }
```

And to make sure you are using the ```canner_scope``` do the following:
``` ruby
after_action :ensure_scope, only: :index
```

Note the use of only here.  You usually won't need the canner_scope on anything except
for the index to be strictly enforced.

And finally, if you want to enforce that you are using instance_can? use something like:
``` ruby
after_action :ensure_instance_checking, only: [:edit, :destroy, :update]
```

If you would like to skip one of the enforcements for a specific controller add one or all of these:

``` ruby
skip_filter :ensure_scope
skip_filter :ensure_auth
skip_filter :ensure_instance_checking
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

## Testing

See the wiki for some testing tips
[Testing](https://github.com/jacklin10/canner/wiki/Testing)
