/*
	AS3 Piwik Tracker
	
	Link git://github.com/bpouzet/AS3-Piwik-Tracker.git
	Licence released under BSD License http://www.opensource.org/licenses/bsd-license.php

*/
package org.piwik.tracker
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Capabilities;

	/**
	 * 
	 * AS3 Piwik Tracker
	 * 
	 * <p>
	 * Allows you to track user in your Flash/Flex/AIR project
	 * </p>
	 * 
	 * <p>
	 * Need at least Piwik version 1.6
	 * </p> 
	 * 
	 * 
	 * @see git://github.com/bpouzet/AS3-Piwik-Tracker.git
	 * @see http://piwik.org/docs/tracking-api/
	 * @see http://piwik.org/docs/ecommerce-analytics/
	 * 
	 * @author Benoit Pouzet
	 * 
	 * @langversion 3.0
	 * 
	 */
	public class PiwikTracker
	{
		//--------------------------------------------------------------------------
		//
		// Variables
		// 
		//--------------------------------------------------------------------------
	
		private var cookie:SharedObject;
		
		private var urlTracker:String;
		private var idSiteTracker:int;
		private var appUrlTracker:String;
		
		private var urlRequest:URLRequest;
		private var requestVars:URLVariables;
		
		private var visitCount:int;
		
		private var ecommerceItems:Array;
		private var lastEcommerceOrderTs:int;
		
		/**
		 * Construct a new AS3 Piwik Tracker
		 * 
		 * <p>Example</br>
		 * <code>var tracker:PiwikTracker = new PiwikTracker("http://demo.piwik.org/", 1, "http://piwik.org/as3/");</code>
		 * </p>
		 * 
		 * @param piwikAccessUrl Your Tracking REST API endpoint
		 * @param idSite Defines the Website ID being tracked
		 * @param appUrl Set the url of your application
		 */
		public function PiwikTracker(piwikAccessUrl:String, idSite:int, appUrl:String)
		{
			cookie = SharedObject.getLocal("AS3PiwikTracker");
			
			urlTracker = piwikAccessUrl + "piwik.php";
			idSiteTracker = idSite;
			appUrlTracker = appUrl;
			
			setUrlRequest();
			setRequestVars();
			
			visitCount = 1;
			ecommerceItems = new Array();
		}
		
		private function setUrlRequest():void{
			urlRequest = new URLRequest(urlTracker);
			urlRequest.method = URLRequestMethod.GET;
			urlRequest.contentType = "application/x-www-form-urlencoded";
		}
		
		private function setRequestVars():void{
			/** Check config **/
			var idTracker:String;
			var dateTracker:int;
			var res:String;
			
			var w:Number = Capabilities.screenResolutionX;
			var h:Number = Capabilities.screenResolutionY;
			
			res = w + "x" + h;
			
			var d:Date = new Date();
			
			if(!cookie.data.uuid){
				// uuid - generate a pseudo-unique ID to fingerprint this user;
				// note: this isn't a RFC4122-compliant UUID
				idTracker = (d.time * Math.random() * 10000).toString().slice(0, 16);
				cookie.data.uuid = idTracker;
				showDebug("uuid created: " + idTracker);
			}else{
				idTracker = cookie.data.uuid;
				showDebug("uuid: " + idTracker);
			}
			
			if(!cookie.data.lastEcommerceOrderTs || (cookie.data.lastEcommerceOrderTs == 0)){
				lastEcommerceOrderTs = 0;
			}else{
				lastEcommerceOrderTs = cookie.data.lastEcommerceOrderTs;
			}
			
			
			dateTracker = d.time/1000;
			
			/** Set request variables **/
			requestVars = new URLVariables();
			
			// Set unique user id
			requestVars._id = idTracker;
			requestVars._idn = 0;
			requestVars._idts = dateTracker;
			
			requestVars._refts = 0;
			requestVars._viewts = dateTracker;
			
			
			// Set the website ID
			requestVars.idsite = idSiteTracker;
			
			// Set to force the request to be recorded
			requestVars.rec = 1;
			
			// Set API version
			requestVars.apiv = 1;
			
			requestVars.cookie = 1;
			requestVars.fla = 1;
			
			// Set the resolution
			requestVars.res = res;
		}
		
		/**
		 * Tracks a page/view.
		 * 
		 * @param documentTitle Page title
		 * 
		 */
		public function trackPageView(documentTitle:String):void{
			// Set the url to track
			requestVars.url = appUrlTracker+documentTitle;
			
			// Set the page title
			requestVars.action_name = documentTitle;
			
			tracking();
		}
		/**
		 * Tracks action.
		 * 
		 * @param actionUrl The URL of the download or outlink
		 * @param actionType Type of action "download" or "link"
		 * 
		 */
		public function trackAction(actionUrl:String, actionType:String):void{
			// Set the download url or the external url
			switch(actionType){
				case 'download':
					requestVars.download = actionUrl;
					break;
				case 'link':
					requestVars.link = actionUrl;
					break;
				
				default:
					requestVars.link = actionUrl;
					break;
			}
			
			tracking();
		}
		/**
		 * Tracks goal.
		 * 
		 * @param idGoal The id goal
		 * @param revenue The revenue of the goal
		 * 
		 */
		public function trackGoal(idGoal:int, revenue:Number=0):void{
			// Set the given goal
			requestVars.idgoal = idGoal;
			if(revenue>0) requestVars.revenue = revenue;
			
			tracking();
		}
		
		/** Ecommerce **/
		
		/**
		 * Adds an item in the ecommerce order.
		 * 
		 * <p>This should be called before <code>trackEcommerceOrder()</code>, or before <code>trackEcommerceCartUpdate()</code>. 
		 * This function can be called for all individual products in the cart (or order). 
		 * SKU parameter is mandatory. Other parameters are optional. 
		 * Ecommerce items added via this function are automatically cleared when <code>trackEcommerceOrder()</code> is called.</p>
		 * 
		 * @param sku The product SKU
		 * @param name The product name
		 * @param category Array of product categories
		 * @param price The product price
		 * @param quantity The product quantity
		 * 
		 */
		public function addEcommerceItem(productSKU:String, productName:String=null, productCategory:Array=null, price:Number=0, quantity:int=1):void{
			
			var category:String="";
			
			if(productCategory.length > 0){
				
				for each(var val:String in productCategory){
					category += '"' + val + '",';
				}
				category = category.substr(0, category.length-1);
			}
			
			var item:String = '["'+productSKU+'", "'+productName+'", ['+category+'], '+price+', '+quantity+']';
			
			ecommerceItems.push(item);
		}
		/**
		 * Tracks a cart update.
		 * 
		 * <p>On every Cart update, you must call addEcommerceItem() for each item (product) in the cart, including the items that haven't been updated since the last cart update. 
		 * Items which were in the previous cart and are not sent in later Cart updates will be deleted from the cart (in the database).</p>
		 * 
		 * @param grandTotal Cart grandTotal (sum of all items' prices)
		 * 
		 */
		public function trackEcommerceCartUpdate(grandTotal:Number):void{
			
			trackEcommerceOrder('0', grandTotal);
		}
		
		/**
		 * Tracks an ecommerce order.
		 * 
		 * <p>If the Ecommerce order contains items (products), you must call first the addEcommerceItem() for each item in the order. 
		 * All revenues (grandTotal, subTotal, tax, shipping, discount) will be individually summed and reported in Piwik reports.</p>
		 * 
		 * @param orderId Unique Order ID
		 * @param grandTotal Grand total revenue of the transaction (including tax, shipping, etc.)
		 * @param subTotal Sub total amount, sum of items prices in this order (before Tax and Shipping costs are applied)
		 * @param tax Tax amount for this order
		 * @param shipping Shipping amount for this order
		 * @param discount Discounted amount in this order
		 * 
		 */
		public function trackEcommerceOrder(orderId:String, grandTotal:Number, subTotal:Number=0, tax:Number=0, shipping:Number=0, discount:Number=0):void{
			requestVars.idgoal = 0;
			var currentEcommerceOrderTs:int = 0;
			
			if(orderId != '0') {
				requestVars.ec_id = orderId;
				
				// Record date of order in the visitor cookie
				currentEcommerceOrderTs = Math.round(new Date().time / 1000000);
			}
			requestVars.revenue = grandTotal;
			
			if(subTotal > 0) requestVars.ec_st = subTotal;
			
			if(tax > 0) requestVars.ec_tx = tax;
			
			if(shipping > 0) requestVars.ec_sh = shipping;
			
			if(discount > 0) requestVars.ec_dt = discount;
			else requestVars.ec_dt = false;
			
			if(ecommerceItems){
				
				requestVars.ec_items = '[' + ecommerceItems.toString() + ']';
			}
			
			tracking(currentEcommerceOrderTs);
			
			// clean ecommerceItems
			ecommerceItems = new Array();
		}
		
		
		/**
		 * Tracks the page/view as an ecommerce category page/view
		 * 
		 * <p><code>trackPageView()</code> will automatilly be called</p>
		 * 
		 * @param documentTitle Page title
		 * @param category Array of product categories 
		 * 
		 */
		public function trackEcommerceCategoryView(documentTitle:String, category:Array):void{
			
			setEcommerceView(documentTitle, 'category', '', '', category);
			
		}
		/**
		 * Tracks the page/view as an item (product) page/view
		 * 
		 * <p><code>trackPageView()</code> will automatilly be called</p>
		 * 
		 * @param documentTitle Page title
		 * @param productSku The product SKU
		 * @param productName The product name
		 * @param productCategory Array of product categories
		 * @param price The product price
		 * 
		 */
		public function trackEcommerceProductView(documentTitle:String, productSku:String="", productName:String="", productCategory:Array=null, price:Number=0):void{
			
			setEcommerceView(documentTitle, 'product', productSku, productName, productCategory, price);
			
		}
		
		/**
		 * 
		 * 
		 */
		private function setEcommerceView(documentTitle:String, type:String, productSku:String="", productName:String="", productCategory:Array=null, price:Number=0):void{
			if(type == "product"){
				
				if(productSku.length > 0){
					requestVars._pks = productSku;
				}else{
					showError("SKU is required.");
				}
				
				if(productName.length > 0) requestVars._pkn = productName;
				
				if(price > 0){
					requestVars._pkp = price;
				}
				
				if(productCategory== null || productCategory.length==0){
					requestVars._pkc = "";
				}else{
					requestVars._pkc = productCategory;
				}
				
			}else if(type == "category"){
				
				if(productCategory== null || productCategory.length==0){
					showError("Category must have at least one value.");
				}
				
				requestVars._pkc = productCategory.toString();
				
				
			}else{
				showError("Error with type of view.");
			}
			
			trackPageView(documentTitle);
		}
			
		/**
		 * 
		 * @param msg
		 * 
		 */
		private function showDebug(msg:String):void{
			if(Capabilities.isDebugger) trace(msg);
		}
		/**
		 * Show an error.
		 * 
		 * @param msg
		 * 
		 */
		private function showError(msg:String):void{
			throw new Error(msg);
		}
		
		/**
		 * 
		 * 
		 */
		private function tracking(currentEcommerceOrderTs:int=0):void{
			// Set a random
			requestVars.rand = Math.random().toString().slice(2,8);
			
			// Set the current count of visits
			requestVars._idvc = visitCount;
			
			var date:Date = new Date();
			// Set the current time
			requestVars.h = date.hours;
			requestVars.m = date.minutes;
			requestVars.s = date.seconds;
			
			if(lastEcommerceOrderTs !=  0) requestVars._ects = lastEcommerceOrderTs;
			
			urlRequest.data = requestVars;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			
			loader.addEventListener(Event.COMPLETE, onComplete, false, 0, true);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError, false, 0, true);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError, false, 0, true);
			
			loader.load(urlRequest);
			
			// increment visit count
			visitCount++;
			
			// update cookie 
			if(currentEcommerceOrderTs !=  0){
				lastEcommerceOrderTs = currentEcommerceOrderTs;
				cookie.data.lastEcommerceOrderTs = lastEcommerceOrderTs;
			}
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */
		private function onComplete(event:Event):void{
			showDebug("Request sent");
		}
		/**
		 * 
		 * @param event
		 * 
		 */
		private function onError(event:IOErrorEvent):void{
			showDebug("IO error");
		}
		/**
		 * 
		 * @param event
		 * 
		 */
		private function onSecurityError(event:SecurityErrorEvent):void{
			showDebug("security error");
		}
	}
}