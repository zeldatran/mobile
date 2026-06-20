package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.OrderStatus;
import com.trannguyendiemhanh.auth.service.OrderStatusService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/order-statuses")
public class OrderStatusController extends CrudController<OrderStatus, UUID> {
    public OrderStatusController(OrderStatusService service) {
        super(service);
    }
}
