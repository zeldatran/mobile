package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Coupon;
import com.trannguyendiemhanh.auth.service.CouponService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/coupons")
public class CouponController extends CrudController<Coupon, UUID> {
    public CouponController(CouponService service) {
        super(service);
    }
}
