AS3 Piwik Tracker 
=================

Allows you to track page/view, goal, download, link, ecommerce from your Flash/Flex/AIR project!


License
-------

AS3 Piwik Tracker is release under a BSD license.
See LEGALNOTICE file.


Usage
-----

- Import AS3 Piwik Tracker library in your project
- Then create a variable and instantiate a PiwikTracker:

		var tracker:PiwikTracker;
		tracker = new PiwikTracker("YOUR_PIWIK_ACCESS_URL", YOUR_PIWIK_WEBSITE_ID, "YOUR_APPLICATION_URL");

- Now you can track page/view, goal, download, link, ecommerce


### Examples of available functions

Create variable and instantiate a PiwikTracker:
	
	var tracker:PiwikTracker = new PiwikTracker("http://yourwebsite.com/piwik/", 1, "http://yourwebsite.com/as3/");

To track a page/view:

	tracker.trackPageView("home");

To track an action:
	
	tracker.trackAction("http://www.exemple.com/file.zip", "download");
	
To track a goal:

	tracker.trackGoal(1, 10);

To track add to Cart with 2 products:

	tracker.addEcommerceItem("SKU0011", "Endurance – Shackleton", new Array("Books"), 17, 1);
	tracker.addEcommerceItem("SKU0321", "Amélie", new Array("DVD Foreign", "Best sellers", "Our pick"), 25, 1);
	tracker.trackEcommerceCartUpdate(42);
	
To track an order containing 2 products:

	tracker.addEcommerceItem("SKU0011", "Endurance – Shackleton", new Array("Books"), 17, 1);
	tracker.addEcommerceItem("SKU0321", "Amélie", new Array("DVD Foreign", "Best sellers", "Our pick"), 25, 1);
	tracker.trackEcommerceOrder("B000111387", 55.5, 42, 8, 5.5, 10);


### Simple example with Flex

In myApp.mxml:

	<s:Application xmlns:fx="http://ns.adobe.com/mxml/2009" 
			   xmlns:s="library://ns.adobe.com/flex/spark" 
			   xmlns:views="views.*"
			   creationComplete="application1_creationCompleteHandler(event)"
			   currentState="home">
		<fx:Script>
			<![CDATA[
				import mx.events.FlexEvent;
				
				import org.piwik.tracker.PiwikTracker;
				
				public var tracker: PiwikTracker;
				
				protected function application1_creationCompleteHandler(event:FlexEvent):void
				{
					// TODO Auto-generated method stub
					// instantiate
					tracker = new PiwikTracker("http://yourwebsite.com/piwik/", 1, 'http://yourwebsite.com/as3/');
					
					// track a page/view
					tracker.trackPageView('home');
				}
				protected function button1_clickHandler(event:MouseEvent):void
				{
					// TODO Auto-generated method stub
					currentState = "view1";
					
					// track a page/view
					tracker.trackPageView('view1');
				}
			]]>
		</fx:Script>
		<fx:Declarations>
			
		</fx:Declarations>
		<s:states>
			<s:State name="home" />
			<s:State name="view1" />
		</s:states>
		
		<s:layout>
			<s:VerticalLayout />
		</s:layout>
		
		<s:Label text="Hello" />
		
		<s:VGroup includeIn="home" width="100%" height="100%">
			<s:Label text="Home" />
			<s:Button label="Go to view1" click="button1_clickHandler(event)" />
		</s:VGroup>
		
		<views:View1 includeIn="view1" width="100%" height="100%" />
	</s:Application>


In views/View1.mxml:

	<s:Group xmlns:fx="http://ns.adobe.com/mxml/2009" 
		 xmlns:s="library://ns.adobe.com/flex/spark" 
		 xmlns:mx="library://ns.adobe.com/flex/mx">
	
		<fx:Script>
			<![CDATA[
				protected function button1_clickHandler(event:MouseEvent):void
				{
					// TODO Auto-generated method stub
					navigateToURL(new URLRequest('http://yourwebsite.com/file.pdf'));

					// Track a download action
					FlexGlobals.topLevelApplication.tracker.trackAction('http://yourwebsite.com/file.pdf', 'download');
				}
			]]>
		</fx:Script>
		
		<fx:Declarations>
			<!-- Placer ici les éléments non visuels (services et objets de valeur, par exemple). -->
		</fx:Declarations>
		<s:layout>
			<s:VerticalLayout />
		</s:layout>
		
		<s:Label text="view1" />
		<s:Button label="Donwload file" click="button1_clickHandler(event)" />
	</s:Group>
	
In Flex 4.5, we don’t use MX applications anymore, but we can use the FlexGlobals class.

Known limitations
-----------------

Testing
-------

All functions have been tested with a test application. But, especially for the ecommerce functions, you should check carefully the data in Piwik and if you found a bug, please, let us know.

Found a bug/issue
-----------------

Please, create an [Issue][1] with an example.

How to contribute
-----------------

### With github

1. Fork it.
2. Create a branch (`git checkout -b my_AS3-Piwik-Tracker`)
3. Commit your changes (`git commit -am "Added feature"`)
4. Push to the branch (`git push origin my_AS3-Piwik-Tracker`)
5. Create an [Issue][1] with a link to your branch

### With Piwik-trac

Go here http://dev.piwik.org/trac/ticket/2775

### Or contact us

You can contact us at bpouzet at gmail.com

More info
---------

About Piwik: http://piwik.org

Piwik Tracking API: http://piwik.org/docs/tracking-api/

Ecommerce tracking: http://piwik.org/docs/ecommerce-analytics/

[1]: https://github.com/bpouzet/AS3-Piwik-Tracker/issues