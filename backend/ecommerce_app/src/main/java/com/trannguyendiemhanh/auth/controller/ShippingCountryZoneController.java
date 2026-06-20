package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.ShippingCountryZone;
import com.trannguyendiemhanh.auth.service.ShippingCountryZoneService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/shipping-country-zones")
public class ShippingCountryZoneController extends CrudController<ShippingCountryZone, UUID> {
    public ShippingCountryZoneController(ShippingCountryZoneService service) {
        super(service);
    }
}
