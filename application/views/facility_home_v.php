<style>
	.message {
	display: block;
	padding: 10px 20px;
	margin: 15px;
	}
	.warning {
	background: #FEFFC8 url('<?php echo base_url()?>Images/Alert_Resized.png') 20px 50% no-repeat;
	border: 1px solid #F1AA2D;
	}
	.message h2 {
	margin-left: 60px;
	margin-bottom: 5px;
	}
	.message p {
	width: auto;
	margin-bottom: 0;
	margin-left: 60px;
	}
	#left_content{
	width:45%;
	float: left;
	}
	#right_content{
	width:45%;
	float: right;
	}
	.information {
	background: #C3E4FD url('<?php echo base_url()?>Images/Notification_Resized.png') 20px 50% no-repeat;
	border: 1px solid #688FDC;
	}
	.graph{
	
	border: 1px solid #739F1D;
	}
	.graph h2{
		margin-left:0;
	}
	#main_content{
	overflow:hidden;
	}
	#full_width{
	float:left;
	width:100%
	} 
	.graph_container{
		margin:0 auto;
		width:800px;	
	}
</style>
<script type="text/javascript">
	$(document).ready(function() {
	var chart = new FusionCharts("<?php echo base_url()?>Scripts/FusionCharts/Charts/Line.swf", "ChartId", "800", "300", "0", "0");
	chart.setDataURL("XML/Line2D.xml");
	chart.render("order_satisfaction");
	
	var myChart = new FusionCharts("<?php echo base_url()?>Scripts/FusionWidgets/Charts/HLinearGauge.swf", "myChartId", "420", "90", "0", "0");
	myChart.setDataURL("XML/Linear5.xml");
	myChart.render("turn_around_time");

	});

</script>
<div id="main_content">
	<div id="left_content">
		<div class="message warning">
			<h2>Potential Stock-outs</h2>
			<p>
				<a class="link">10 Commodities</a> have impending stock-outs!
			</p>
		</div>
		<div class="message warning">
			<h2>Pending Orders</h2>
			<p>
				<a class="link">3 Orders</a> that you made are still pending review by KEMSA!
			</p>
		</div>
	</div>
	<div id="right_content">
		<div class="message information">
			<h2>Dispatched Orders</h2>
			<p>
				Order Number<a class="link">34ER45</a> has been Dispatched from the KEMSA stores.
			</p>
		</div>
		<div class="message graph">
			<h2>Average Turn-around-time for Orders</h2>
			<p>
				
			</p>
			<div id="turn_around_time" class="graph_container"></div>
		</div>
	</div>
	<div id="full_width">
		<div class="message graph"> 
			<h2>Average Order Satisfaction %</h2>
			<p>
				
			</p>
			<div id="order_satisfaction" class="graph_container"></div>
		</div>
	</div>
</div>
