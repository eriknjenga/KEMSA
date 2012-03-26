<?php
if (!defined('BASEPATH'))
	exit('No direct script access allowed');

class Report_Management extends MY_Controller {
	function __construct() {
		parent::__construct();
	}

	public function index() {
		$data['title'] = "System Reports";
		$data['content_view'] = "reports_v";
		$data['banner_text'] = "System Reports";
		$data['link'] = "reports_management";
		$this -> load -> view("template", $data);
	}

}
