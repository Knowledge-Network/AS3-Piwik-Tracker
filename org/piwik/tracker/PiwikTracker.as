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
	 * Need Piwik version 1.6
	 * </p> 
	 * 
	 * 
	 * @author ben
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
		
		private var ecommerceItems:Array;
		private var lastEcommerceOrderTs:int;
		
		/**
		 * Construct a new AS3 Piwik Tracker
		 * 
		 * 
		 * <pre>
		 *  var tracker:PiwikTracker = new PiwikTracker("http://demo.piwik.org/", 1, "http://piwik.org/as3/");
		 * </pre>
		 * 
		 * 
		 * @param piwikAccessUrl
		 * @param idSite
		 * @param appUrl
		 * 
		 */
		public function PiwikTracker(piwikAccessUrl:String, idSite:int, appUrl:String)
		{
			cookie = SharedObject.getLocal("AS3PiwikTracker");
			
			urlTracker = piwikAccessUrl + "piwik.php";
			idSiteTracker = idSite;
			appUrlTracker = appUrl;
			
			setUrlRequest();
			setRequestVars();
			
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
			
			requestVars._id = idTracker;
			requestVars._idn = 0;
			requestVars._idts = dateTracker;
			requestVars._idvc = 1;
			requestVars._refts = 0;
			requestVars._viewts = dateTracker;
			
			requestVars.idsite = idSiteTracker;
			
			requestVars.rec = 1;
			
			requestVars.cookie = 1;
			requestVars.fla = 1;
			
			requestVars.res = res;
		}
		
		/**
		 * Track a page/view
		 * 
		 * @param documentTitle
		 * 
		 */
		public function trackPageView(documentTitle:String):void{
			requestVars.url = appUrlTracker+documentTitle;
			requestVars.action_name = documentTitle;
			
			tracking();
		}
		/**
		 * 
		 * @param actionUrl
		 * @param actionType
		 * 
		 */
		public function trackAction(actionUrl:String, actionType:String):void{
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
		 * 
		 * @param idGoal
		 * @param revenue
		 * 
		 */
		public function trackGoal(idGoal:int, revenue:Number=0):void{
			requestVars.idgoal = idGoal;
			if(revenue>0) requestVars.revenue = revenue;
			
			tracking();
		}
		
		/** Ecommerce **/
		
		/**
		 * 
		 * @param sku
		 * @param name
		 * @param category
		 * @param price
		 * @param quantity
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
		 * 
		 * @param grandTotal
		 * 
		 */
		public function trackEcommerceCartUpdate(grandTotal:Number):void{
			
			trackEcommerceOrder('0', grandTotal);
		}
		
		/**
		 * 
		 * @param orderId
		 * @param grandTotal
		 * @param subTotal
		 * @param tax
		 * @param shipping
		 * @param discount
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
		 * 
		 * @param documentTitle
		 * @param category
		 * 
		 */
		public function trackEcommerceCategoryView(documentTitle:String, category:Array):void{
			
			setEcommerceView(documentTitle, 'category', '', '', category);
			
		}
		/**
		 * 
		 * @param documentTitle
		 * @param productSku
		 * @param productName
		 * @param productCategory
		 * @param price
		 * 
		 */
		public function trackEcommerceProductView(documentTitle:String, productSku:String="", productName:String="", productCategory:Array=null, price:Number=0):void{
			
			setEcommerceView(documentTitle, 'product', productSku, productName, productCategory, price);
			
		}
		
		/**
		 * 
		 * @param documentTitle
		 * @param type
		 * @param productSku
		 * @param productName
		 * @param productCategory
		 * @param price
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
			requestVars.r = Math.random().toString().slice(2,8);
			
			var date:Date = new Date();
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
			showDebug("complete");
		}
		/**
		 * 
		 * @param event
		 * 
		 */
		private function onError(event:IOErrorEvent):void{
			showDebug("error");
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