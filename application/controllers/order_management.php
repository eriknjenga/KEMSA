<?php
class Order_Management extends MY_Controller {

	function __construct() {
		parent::__construct();
	}

	public function index() {
		$this -> listing();
	}

	public function new_order() {
		$data['title'] = "New Order";
		$data['content_view'] = "new_order_v";
		$data['banner_text'] = "New Order";
		$data['link'] = "order_management";
		$data['drug_categories'] = Drug_Category::getAll();
		$data['quick_link'] = "new_order";
		$this -> load -> view("template", $data);
	}

	public function all_deliveries() {
		$data['title'] = "All Deliveries";
		$data['content_view'] = "dispatched_listing_v";
		$data['banner_text'] = "Dispatched Orders";
		$data['link'] = "order_management";
		$data['quick_link'] = "all_deliveries";
		$this -> load -> view("template", $data);
	}

	public function update_delivery_status() {
		$data['title'] = "Update Delivery Status";
		$data['content_view'] = "update_delivery_status_v";
		$data['banner_text'] = "Update Status";
		$data['link'] = "order_management";
		$data['quick_link'] = "all_deliveries";
		$this -> load -> view("template", $data);
	}

	public function listing() {
		$data['title'] = "All Orders";
		$data['content_view'] = "orders_listing_v";
		$data['banner_text'] = "All Orders";
		$data['link'] = "order_management"; 
		$this -> load -> view("template", $data);
	}

}
