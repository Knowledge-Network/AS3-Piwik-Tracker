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
		tracker = new PiwikTracker("YOUR_PIWIK_ACCESS_URL", YOUR_PIWIK_WEBSITE_ID, "THE_NAME_OF_YOUR_APPLICATION");

- Now you can track page/view, goal, download, link, ecommerce


### Examples

To track a page/view:

	tracker.trackPageView("home");

To track an action:
	
	tracker.trackAction("http://www.exemple.com/file.zip", "download");
	
To track a goal:

	tracker.trackGoal(1, 10);
	
Add items and track an order:

	tracker.addEcommerceItem("SKU0011", "Endurance – Shackleton", new Array("Books"), 17, 1);
	tracker.addEcommerceItem("SKU0321", "Amélie", new Array("DVD Foreign", "Best sellers", "Our pick"), 25, 1);
	tracker.trackEcommerceOrder("B000111387", 55.5, 42, 8, 5.5, 10);


More info
---------

About Piwik: http://piwik.org

Piwik Tracking API: http://piwik.org/docs/tracking-api/

Ecommerce tracking: http://piwik.org/docs/ecommerce-analytics/