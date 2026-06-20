package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.ShippingRate;
import com.trannguyendiemhanh.auth.service.ShippingRateService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/shipping-rates")
public class ShippingRateController extends CrudController<ShippingRate, UUID> {
    public ShippingRateController(ShippingRateService service) {
        super(service);
    }
}
