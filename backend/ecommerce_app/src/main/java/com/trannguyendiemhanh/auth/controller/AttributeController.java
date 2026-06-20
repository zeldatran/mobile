package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Attribute;
import com.trannguyendiemhanh.auth.service.AttributeService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/attributes")
public class AttributeController extends CrudController<Attribute, UUID> {
    public AttributeController(AttributeService service) {
        super(service);
    }
}
