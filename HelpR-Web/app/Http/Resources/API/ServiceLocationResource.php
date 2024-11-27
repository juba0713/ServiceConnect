<?php

namespace App\Http\Resources\API;

use App\Models\ProviderServiceAddressMapping;
use Illuminate\Http\Resources\Json\JsonResource;

class ServiceLocationResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        $extention = imageExtention(getSingleMedia($this->category, 'category_image',null));
        return [
            'service_id'                => $this->id,
            'service_name'              => $this->name,
            'category_id'               => $this->category->id,
            'category_name'             => $this->category->name,
            'service_address_mapping'   => $this->providerServiceAddress,
            'category_image'            => getSingleMedia($this->category, 'category_image',null),
            'category_extension'        => $extention,
        ];
    }
}
