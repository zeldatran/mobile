package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.ShippingZone;
import com.trannguyendiemhanh.auth.service.ShippingZoneService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/shipping-zones")
public class ShippingZoneController extends CrudController<ShippingZone, UUID> {
    public ShippingZoneController(ShippingZoneService service) {
        super(service);
    }
}
